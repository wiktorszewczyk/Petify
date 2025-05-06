package org.petify.shelter.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.model.Adoption;
import org.petify.shelter.enums.AdoptionStatus;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.AdoptionRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.petify.shelter.mapper.AdoptionMapper;
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
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        if (pet.isArchived()) {
            throw new IllegalStateException("Pet is no longer available for adoption");
        }

        if (adoptionRepository.existsByPetIdAndUsername(petId, username)) {
            throw new IllegalStateException("You already have a pending adoption request for this pet");
        }

        Adoption adoption = adoptionMapper.toEntity(adoptionRequest);
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
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        List<Adoption> adoptions = adoptionRepository.findByPetShelter(shelter);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<AdoptionResponse> getPetAdoptionForms(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        List<Adoption> adoptions = adoptionRepository.findByPet(pet);
        return adoptions.stream()
                .map(adoptionMapper::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdoptionResponse updateAdoptionStatus(Long formId, AdoptionStatus newStatus, String username) {
        Adoption form = adoptionRepository.findById(formId)
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        if (!form.getPet().getShelter().getOwnerUsername().equals(username)) {
            throw new SecurityException("You don't have permission to update this adoption form");
        }

        if (newStatus == AdoptionStatus.APPROVED) {
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
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        if (!form.getUsername().equals(username)) {
            throw new SecurityException("You don't have permission to cancel this adoption form");
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
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        return adoptionMapper.toDto(form);
    }
}
