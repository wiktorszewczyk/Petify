package org.petify.shelter.service;

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
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.AdoptionRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;

import lombok.AllArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class AdoptionService {
    private final AdoptionRepository adoptionRepository;
    private final ShelterRepository shelterRepository;
    private final PetRepository petRepository;
    private final AdoptionMapper adoptionMapper;

    @Transactional
    public AdoptionResponse createAdoptionForm(Long petId, String username, AdoptionRequest adoptionRequest) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        if (pet.isArchived()) {
            throw new PetIsArchivedException(petId);
        }

        if (adoptionRepository.existsByPetIdAndUsername(petId, username)) {
            throw new AdoptionAlreadyExistsException(petId, username);
        }

        Adoption adoption = adoptionMapper.toEntity(adoptionRequest);
        adoption.setUsername(username);
        adoption.setPet(pet);
        Adoption savedForm = adoptionRepository.save(adoption);

        return adoptionMapper.toDto(savedForm);
    }

    public List<AdoptionResponse> getUserAdoptionForms(String username) {
        List<Adoption> adoptions = adoptionRepository.findByUsername(username);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<AdoptionResponse> getShelterAdoptionForms(Long shelterId) {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        List<Adoption> adoptions = adoptionRepository.findByPetShelter(shelter);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<AdoptionResponse> getPetAdoptionForms(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        List<Adoption> adoptions = adoptionRepository.findByPet(pet);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdoptionResponse updateAdoptionStatus(Long formId, AdoptionStatus newStatus, String username) {
        Adoption form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        if (!form.getPet().getShelter().getOwnerUsername().equals(username)) {
            throw new AccessDeniedException("You are not allowed to update this adoption form");
        }

        if (newStatus == AdoptionStatus.ACCEPTED) {
            List<Adoption> otherPendingForms = adoptionRepository
                    .findByPetAndAdoptionStatusAndIdNot(form.getPet(), AdoptionStatus.PENDING, formId);

            for (Adoption otherForm : otherPendingForms) {
                otherForm.setAdoptionStatus(AdoptionStatus.REJECTED);
                adoptionRepository.save(otherForm);
            }

            Pet pet = form.getPet();
            pet.setArchived(true);
            petRepository.save(pet);
        }

        form.setAdoptionStatus(newStatus);
        Adoption updatedForm = adoptionRepository.save(form);

        return adoptionMapper.toDto(updatedForm);
    }

    @Transactional
    public AdoptionResponse cancelAdoptionForm(Long formId, String username) {
        Adoption form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        if (!form.getUsername().equals(username)) {
            throw new AccessDeniedException("You can only cancel your own adoption forms.");
        }

        if (form.getAdoptionStatus() != AdoptionStatus.PENDING) {
            throw new IllegalStateException("Only pending adoption forms can be cancelled");
        }

        form.setAdoptionStatus(AdoptionStatus.CANCELLED);
        Adoption updatedForm = adoptionRepository.save(form);

        return adoptionMapper.toDto(updatedForm);
    }

    public AdoptionResponse getAdoptionFormById(Long formId) {
        Adoption form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new AdoptionFormNotFoundException(formId));

        return adoptionMapper.toDto(form);
    }
}
