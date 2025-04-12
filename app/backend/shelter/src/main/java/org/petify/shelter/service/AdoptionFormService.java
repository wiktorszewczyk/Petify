package org.petify.shelter.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionFormResponse;
import org.petify.shelter.model.AdoptionForm;
import org.petify.shelter.model.AdoptionStatus;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.AdoptionFormRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class AdoptionFormService {
    private final AdoptionFormRepository adoptionFormRepository;
    private final ShelterRepository shelterRepository;
    private final PetRepository petRepository;

    @Transactional
    public AdoptionFormResponse createAdoptionForm(Long petId, Integer userId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        if (pet.isArchived()) {
            throw new IllegalStateException("Pet is no longer available for adoption");
        }

        if (adoptionFormRepository.existsByPetIdAndUserId(petId, userId)) {
            throw new IllegalStateException("You already have a pending adoption request for this pet");
        }

        AdoptionForm adoptionForm = new AdoptionForm();
        adoptionForm.setUserId(userId);
        adoptionForm.setPet(pet);
        adoptionForm.setAdoptionStatus(AdoptionStatus.PENDING);

        AdoptionForm savedForm = adoptionFormRepository.save(adoptionForm);

        return mapToResponse(savedForm);
    }

    public List<AdoptionFormResponse> getUserAdoptionForms(Integer userId) {
        List<AdoptionForm> adoptionForms = adoptionFormRepository.findByUserId(userId);
        return adoptionForms.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<AdoptionFormResponse> getShelterAdoptionForms(Long shelterId) {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        List<AdoptionForm> adoptionForms = adoptionFormRepository.findByPetShelter(shelter);
        return adoptionForms.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<AdoptionFormResponse> getPetAdoptionForms(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        List<AdoptionForm> adoptionForms = adoptionFormRepository.findByPet(pet);
        return adoptionForms.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdoptionFormResponse updateAdoptionStatus(Long formId, AdoptionStatus newStatus, Integer shelterOwnerId) {
        AdoptionForm form = adoptionFormRepository.findById(formId)
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        if (!form.getPet().getShelter().getOwnerId().equals(shelterOwnerId)) {
            throw new SecurityException("You don't have permission to update this adoption form");
        }

        if (newStatus == AdoptionStatus.APPROVED) {
            List<AdoptionForm> otherPendingForms = adoptionFormRepository
                    .findByPetAndAdoptionStatusAndIdNot(form.getPet(), AdoptionStatus.PENDING, formId);

            for (AdoptionForm otherForm : otherPendingForms) {
                otherForm.setAdoptionStatus(AdoptionStatus.REJECTED);
                adoptionFormRepository.save(otherForm);
            }

            Pet pet = form.getPet();
            pet.setArchived(true);
            petRepository.save(pet);
        }

        form.setAdoptionStatus(newStatus);
        AdoptionForm updatedForm = adoptionFormRepository.save(form);

        return mapToResponse(updatedForm);
    }

    @Transactional
    public AdoptionFormResponse cancelAdoptionForm(Long formId, Integer userId) {
        AdoptionForm form = adoptionFormRepository.findById(formId)
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        if (!form.getUserId().equals(userId)) {
            throw new SecurityException("You don't have permission to cancel this adoption form");
        }

        if (form.getAdoptionStatus() != AdoptionStatus.PENDING) {
            throw new IllegalStateException("Only pending adoption forms can be cancelled");
        }

        form.setAdoptionStatus(AdoptionStatus.CANCELLED);
        AdoptionForm updatedForm = adoptionFormRepository.save(form);

        return mapToResponse(updatedForm);
    }

    public AdoptionFormResponse getAdoptionFormById(Long formId) {
        AdoptionForm form = adoptionFormRepository.findById(formId)
                .orElseThrow(() -> new EntityNotFoundException("Adoption form with id " + formId + " not found!"));

        return mapToResponse(form);
    }

    private AdoptionFormResponse mapToResponse(AdoptionForm form) {
        return new AdoptionFormResponse(
                form.getId(),
                form.getUserId(),
                form.getPet().getId(),
                form.getAdoptionStatus().toString()
        );
    }
}
