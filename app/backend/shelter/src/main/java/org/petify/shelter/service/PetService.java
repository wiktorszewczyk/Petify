package org.petify.shelter.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class PetService {
    private final PetRepository petRepository;
    private final ShelterRepository shelterRepository;

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
    public PetResponse createPet(PetRequest petRequest, Long shelterId, MultipartFile imageFile) throws IOException {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        Pet pet = new Pet(petRequest.name(), petRequest.type(), petRequest.breed(), petRequest.age(), petRequest.description(), shelter);
        pet.setImageName(imageFile.getOriginalFilename());
        pet.setImageType(imageFile.getContentType());
        pet.setImageData(imageFile.getBytes());

        Pet savedPet = petRepository.save(pet);

        return new PetResponse(
                savedPet.getId(),
                savedPet.getName(),
                savedPet.getType(),
                savedPet.getBreed(),
                savedPet.getAge(),
                savedPet.isArchived(),
                savedPet.getDescription(),
                savedPet.getShelter().getId()
        );
    }

    public PetImageResponse getPetImage(Long id) {
        Optional<Pet> pet = petRepository.findById(id);
        if (pet.isPresent()) {
            return new PetImageResponse(pet.get().getImageName(), pet.get().getImageType(), pet.get().getImageData());
        } else {
            throw new EntityNotFoundException("Pet with id " + id + " not found!");
        }
    }

    @Transactional
    public PetResponse updatePet(PetRequest petRequest, Long petId, Long shelterId, MultipartFile imageFile) throws IOException {
        Pet existingPet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        existingPet.setName(petRequest.name());
        existingPet.setType(petRequest.type());
        existingPet.setBreed(petRequest.breed());
        existingPet.setAge(petRequest.age());
        existingPet.setDescription(petRequest.description());
        existingPet.setShelter(shelter);

        if (imageFile != null && !imageFile.isEmpty()) {
            existingPet.setImageName(imageFile.getOriginalFilename());
            existingPet.setImageType(imageFile.getContentType());
            existingPet.setImageData(imageFile.getBytes());
        }

        Pet updatedPet = petRepository.save(existingPet);

        return new PetResponse(
                updatedPet.getId(),
                updatedPet.getName(),
                updatedPet.getType(),
                updatedPet.getBreed(),
                updatedPet.getAge(),
                updatedPet.isArchived(),
                updatedPet.getDescription(),
                updatedPet.getShelter().getId()
        );
    }

    @Transactional
    public void deletePet(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        petRepository.delete(pet);
    }

    @Transactional
    public PetResponse archivePet(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found!"));

        pet.setArchived(true);
        Pet savedPet = petRepository.save(pet);

        return new PetResponse(
                savedPet.getId(),
                savedPet.getName(),
                savedPet.getType(),
                savedPet.getBreed(),
                savedPet.getAge(),
                savedPet.isArchived(),
                savedPet.getDescription(),
                savedPet.getShelter().getId()
        );
    }
}
