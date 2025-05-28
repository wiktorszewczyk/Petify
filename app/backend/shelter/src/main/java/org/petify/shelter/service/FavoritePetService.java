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
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@Service
public class FavoritePetService {
    private final FavoritePetRepository favoritePetRepository;
    private final PetRepository petRepository;
    private final PetMapper petMapper;

    @Transactional
    public boolean save(String username, Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        if (pet.isArchived() || !pet.getShelter().getIsActive()) {
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

    @Transactional
    public boolean delete(String username, Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        Optional<FavoritePet> favoritePet = favoritePetRepository.findByUsernameAndPet(username, pet);
        favoritePet.ifPresent(favoritePetRepository::delete);
        return favoritePet.isPresent();
    }

    @Transactional
    public List<PetResponse> getFavoritePets(String username) {
        return favoritePetRepository.findByUsername(username)
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .filter(pet -> pet.getShelter().getIsActive())
                .map(petMapper::toDto)
                .toList();
    }
}
