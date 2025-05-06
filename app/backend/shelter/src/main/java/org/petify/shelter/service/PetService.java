package org.petify.shelter.service;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class PetService {
    private final PetRepository petRepository;
    private final ShelterRepository shelterRepository;
    private final PetMapper petMapper;

    public List<PetResponse> getPets() {
        List<Pet> pets = petRepository.findAll();
        List<PetResponse> petsList = new ArrayList<>();
        for (Pet pet : pets) {
            petsList.add(petMapper.toDto(pet));
        }

        return petsList;
    }

    public PetResponse getPetById(Long petId) {
        return petRepository.findById(petId)
                .map(petMapper::toDto)
                .orElseThrow(() -> new EntityNotFoundException("Pet with id " + petId + " not found"));
    }

    public List<PetResponse> getAllShelterPets(Long shelterId) {
        return petRepository.findByShelterId(shelterId)
                .orElse(Collections.emptyList())
                .stream()
                .map(petMapper::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public PetResponse createPet(PetRequest petRequest, Long shelterId, MultipartFile imageFile) throws IOException {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        Pet pet = petMapper.toEntity(petRequest, shelter);
        pet.setImageName(imageFile.getOriginalFilename());
        pet.setImageType(imageFile.getContentType());
        pet.setImageData(imageFile.getBytes());

        Pet savedPet = petRepository.save(pet);

        return petMapper.toDto(savedPet);
    }

    public PetImageResponse getPetImage(Long id) {
        Optional<Pet> pet = petRepository.findById(id);
        if (pet.isPresent()) {
            return new PetImageResponse(pet.get().getImageName(), pet.get().getImageType(), Base64.getEncoder().encodeToString(pet.get().getImageData()));
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
        existingPet.setKidFriendly(petRequest.kidFriendly());
        existingPet.setSterilized(petRequest.sterilized());
        existingPet.setUrgent(petRequest.urgent());
        existingPet.setVaccinated(petRequest.vaccinated());
        existingPet.setGender(petRequest.gender());

        if (imageFile != null && !imageFile.isEmpty()) {
            existingPet.setImageName(imageFile.getOriginalFilename());
            existingPet.setImageType(imageFile.getContentType());
            existingPet.setImageData(imageFile.getBytes());
        }

        Pet updatedPet = petRepository.save(existingPet);

        return petMapper.toDto(updatedPet);
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

        return petMapper.toDto(savedPet);
    }
}
