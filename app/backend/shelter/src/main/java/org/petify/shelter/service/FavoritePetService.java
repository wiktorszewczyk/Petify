package org.petify.shelter.service;

import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@Service
public class FavoritePetService {
    private final FavoritePetRepository favoritePetRepository;
    private final PetRepository petRepository;
    private final PetMapper petMapper;

    public boolean save(String username, Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        if (pet.isArchived()) {
            return false;
        }

        FavoritePet favoritePet = new FavoritePet();
        favoritePet.setUsername(username);
        favoritePet.setPet(pet);

        try {
            favoritePetRepository.save(favoritePet);
            return true;
        } catch (DataIntegrityViolationException e) {
            return false;
        }
    }

    public boolean delete(String username, Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        Optional<FavoritePet> favoritePet = favoritePetRepository.findByUsernameAndPet(username, pet);
        favoritePet.ifPresent(favoritePetRepository::delete);
        return favoritePet.isPresent();
    }

    public List<PetResponse> getFavoritePets(String username) {
        return favoritePetRepository.findByUsername(username)
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .map(petMapper::toDto)
                .toList();
    }
}
