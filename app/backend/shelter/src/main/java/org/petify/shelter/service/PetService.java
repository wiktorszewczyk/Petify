package org.petify.shelter.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class PetService {
    private PetRepository petRepository;
    private ShelterRepository shelterRepository;

    public List<PetResponse> getPets() {
        List<Pet> pets = petRepository.findAll();
        List<PetResponse> petsList = new ArrayList<>();
        for (Pet pet : pets) {
            petsList.add(new PetResponse(pet.getId(), pet.getName(), pet.getType(),
                    pet.getBreed(), pet.getAge(), pet.isArchived(), pet.getDescription(), pet.getShelter().getId()));
        }

        return petsList;
    }

    public PetResponse getPetById(Long petId) {
        return petRepository.findById(petId)
                .map(pet -> new PetResponse(pet.getId(), pet.getName(), pet.getType(),
                        pet.getBreed(), pet.getAge(), pet.isArchived(), pet.getDescription(), pet.getShelter().getId()))
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found"));
    }

    public List<PetResponse> getAllShelterPets(Long shelterId) {
        return petRepository.findByShelterId(shelterId)
                .orElse(Collections.emptyList())
                .stream()
                .map(pet -> new PetResponse(
                        pet.getId(),
                        pet.getName(),
                        pet.getType(),
                        pet.getBreed(),
                        pet.getAge(),
                        pet.isArchived(),
                        pet.getDescription(),
                        pet.getShelter().getId()
                ))
                .collect(Collectors.toList());
    }

    @Transactional
    public PetResponse createPet(PetRequest request, Long shelterId) {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        Pet pet = new Pet(request.name(), request.type(), request.breed(), request.age(), request.description(), shelter);
        Pet savedPet = petRepository.save(pet);

        return new PetResponse(savedPet.getId(), savedPet.getName(), savedPet.getType(), savedPet.getBreed(), savedPet.getAge(), savedPet.isArchived(), savedPet.getDescription(), savedPet.getShelter().getId());
    }
}
