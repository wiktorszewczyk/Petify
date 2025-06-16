package org.petify.shelter.service;

import org.petify.shelter.client.AchievementClient;
import org.petify.shelter.dto.PetResponseWithImages;
import org.petify.shelter.enums.MatchType;
import org.petify.shelter.exception.PetIsArchivedException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.exception.ShelterIsNotActiveException;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@RequiredArgsConstructor
@Service
public class FavoritePetService {
    private final FavoritePetRepository favoritePetRepository;
    private final PetRepository petRepository;
    private final PetMapper petMapper;
    private final AchievementClient achievementClient;

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

        try {
            achievementClient.trackLikeProgress();
            log.info("Successfully tracked like progress for user: {}", username);
        } catch (Exception e) {
            log.error("Failed to track achievement progress for like action by user: {}", username, e);
        }
    }

    @Transactional
    public void dislike(String username, Long petId) {
        upsertFavoritePet(username, petId, MatchType.DISLIKE);
    }

    @Transactional
    public void support(String username, Long petId) {
        upsertFavoritePet(username, petId, MatchType.SUPPORT);

        try {
            achievementClient.trackSupportProgress();
            log.info("Successfully tracked support progress for user: {}", username);
        } catch (Exception e) {
            log.error("Failed to track achievement progress for support action by user: {}", username, e);
        }
    }

    @Transactional(readOnly = true)
    public List<PetResponseWithImages> getFavoritePets(String username) {
        return favoritePetRepository.findByUsernameAndStatus(username, MatchType.LIKE)
                .orElse(List.of())
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .filter(pet -> pet.getShelter().getIsActive())
                .map(petMapper::toDtoWithImages)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PetResponseWithImages> getSupportedPets(String username) {
        return favoritePetRepository.findByUsernameAndStatus(username, MatchType.SUPPORT)
                .orElse(List.of())
                .stream()
                .map(FavoritePet::getPet)
                .filter(pet -> !pet.isArchived())
                .filter(pet -> pet.getShelter().getIsActive())
                .map(petMapper::toDtoWithImages)
                .toList();
    }
}
