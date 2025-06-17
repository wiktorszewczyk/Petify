package org.petify.shelter.service;

import org.petify.shelter.client.AchievementClient;
import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.enums.AdoptionStatus;
import org.petify.shelter.exception.AdoptionAlreadyExistsException;
import org.petify.shelter.exception.AdoptionFormNotFoundException;
import org.petify.shelter.exception.PetIsArchivedException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.AdoptionMapper;
import org.petify.shelter.model.Adoption;
import org.petify.shelter.repository.AdoptionRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;

import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
@Slf4j
public class AdoptionService {
    private final AdoptionRepository adoptionRepository;
    private final ShelterRepository shelterRepository;
    private final PetRepository petRepository;
    private final AdoptionMapper adoptionMapper;
    private final AchievementClient achievementClient;

    @Transactional
    public AdoptionResponse createAdoptionForm(Long petId, String username, AdoptionRequest adoptionRequest) {
        var pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        if (pet.isArchived()) {
            throw new PetIsArchivedException(petId);
        }

        if (adoptionRepository.existsByPetIdAndUsername(petId, username)) {
            throw new AdoptionAlreadyExistsException(petId, username);
        }

        var adoption = adoptionMapper.toEntity(adoptionRequest);
        adoption.setUsername(username);
        adoption.setPet(pet);
        var savedForm = adoptionRepository.save(adoption);

        return adoptionMapper.toDto(savedForm);
    }

    public List<AdoptionResponse> getUserAdoptionForms(String username) {
        var adoptions = adoptionRepository.findByUsername(username);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<AdoptionResponse> getShelterAdoptionForms(Long shelterId) {
        var shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        var adoptions = adoptionRepository.findByPetShelter(shelter);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<AdoptionResponse> getPetAdoptionForms(Long petId) {
        var pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        var adoptions = adoptionRepository.findByPet(pet);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdoptionResponse updateAdoptionStatus(Long formId, AdoptionStatus newStatus, String username) {
        var form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        if (!form.getPet().getShelter().getOwnerUsername().equals(username)) {
            throw new AccessDeniedException("You are not allowed to update this adoption form");
        }

        if (newStatus == AdoptionStatus.ACCEPTED) {
            var otherPendingForms = adoptionRepository
                    .findByPetAndAdoptionStatusAndIdNot(form.getPet(), AdoptionStatus.PENDING, formId);

            for (Adoption otherForm : otherPendingForms) {
                otherForm.setAdoptionStatus(AdoptionStatus.REJECTED);
                adoptionRepository.save(otherForm);
            }

            var pet = form.getPet();
            pet.setArchived(true);
            petRepository.save(pet);

            try {
                achievementClient.trackAdoptionProgressForUser(form.getUsername());
                log.info("Tracked adoption achievement for user: {}", form.getUsername());
            } catch (Exception e) {
                log.error("Failed to track adoption achievement for user {}: {}", 
                         form.getUsername(), e.getMessage());
            }
        }

        form.setAdoptionStatus(newStatus);
        var updatedForm = adoptionRepository.save(form);

        return adoptionMapper.toDto(updatedForm);
    }

    @Transactional
    public AdoptionResponse cancelAdoptionForm(Long formId, String username) {
        var form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        if (!form.getUsername().equals(username)) {
            throw new AccessDeniedException("You can only cancel your own adoption forms.");
        }

        if (form.getAdoptionStatus() != AdoptionStatus.PENDING) {
            throw new IllegalStateException("Only pending adoption forms can be cancelled");
        }

        form.setAdoptionStatus(AdoptionStatus.CANCELLED);
        var updatedForm = adoptionRepository.save(form);

        return adoptionMapper.toDto(updatedForm);
    }

    @Transactional
    public void deleteAdoptionForm(Long formId, String username) {
        Adoption form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        if (!form.getPet().getShelter().getOwnerUsername().equals(username)) {
            throw new AccessDeniedException("You are not allowed to delete this adoption form.");
        }

        if (form.getAdoptionStatus() == AdoptionStatus.PENDING || form.getAdoptionStatus() == AdoptionStatus.ACCEPTED) {
            throw new IllegalStateException("You cannot delete a pending or accepted adoption form. Please reject or cancel it first.");
        }

        adoptionRepository.delete(form);
    }

    public AdoptionResponse getAdoptionFormById(Long formId) {
        var form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        return adoptionMapper.toDto(form);
    }

    public List<AdoptionResponse> getAdoptionsByUsername(String username) {
        List<Adoption> adoptions = adoptionRepository.findByUsername(username);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }
}
