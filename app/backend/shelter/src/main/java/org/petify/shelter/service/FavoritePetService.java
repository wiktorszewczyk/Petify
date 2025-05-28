package org.petify.shelter.service;

import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.enums.MatchType;
import org.petify.shelter.exception.PetIsArchivedException;
import org.petify.shelter.exception.ShelterIsNotActiveException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@RequiredArgsConstructor
@Service
public class FavoritePetService {
    private final FavoritePetRepository favoritePetRepository;
    private final PetRepository petRepository;
    private final PetMapper petMapper;

    private void upsertFavoritePet(String username, Long petId, MatchType status) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        if (pet.isArchived()) {
            throw new PetIsArchivedException(petId);
        } else if (!pet.getShelter().getIsActive()) {
            throw new ShelterIsNotActiveException();
        }

        FavoritePet favoritePet = favoritePetRepository.findByUsernameAndPetId(username, petId)
                .orElseGet(() -> {
                    FavoritePet newFavorite = new FavoritePet();
                    newFavorite.setUsername(username);
                    newFavorite.setPet(pet);
                    return newFavorite;
                });

        favoritePet.setStatus(status);
        favoritePetRepository.save(favoritePet);
    }

    @Transactional
    public void like(String username, Long petId) {
        upsertFavoritePet(username, petId, MatchType.LIKE);
    }

    @Transactional
    public void dislike(String username, Long petId) {
        upsertFavoritePet(username, petId, MatchType.DISLIKE);
    }

    @Transactional
    public void support(String username, Long petId) {
        upsertFavoritePet(username, petId, MatchType.SUPPORT);
    }

    @Transactional
    public List<PetResponse> getFavoritePets(String username) {
        return favoritePetRepository.findByUsernameAndStatus(username, MatchType.LIKE)
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .filter(pet -> pet.getShelter().getIsActive())
                .map(petMapper::toDto)
                .toList();
    }

    @Transactional
    public List<PetResponse> getSupportedPets(String username) {
        return favoritePetRepository.findByUsernameAndStatus(username, MatchType.SUPPORT)
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .filter(pet -> pet.getShelter().getIsActive())
                .map(petMapper::toDto)
                .toList();
    }
}
