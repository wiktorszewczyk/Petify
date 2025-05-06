package org.petify.shelter.service;

import lombok.RequiredArgsConstructor;
import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@Service
public class FavoritePetService {
    private final FavoritePetRepository favoritePetRepository;
    private final PetRepository petRepository;

    public boolean save(String username, Long petId) {
        Optional<Pet> petOpt = petRepository.findById(petId);
        if (petOpt.isEmpty()) return false;

        FavoritePet favoritePet = new FavoritePet();
        favoritePet.setUsername(username);
        favoritePet.setPet(petOpt.get());

        try {
            favoritePetRepository.save(favoritePet);
            return true;
        } catch (DataIntegrityViolationException e) {
            return false;
        }
    }

    public boolean delete(String username, Long petId) {
        Optional<Pet> petOpt = petRepository.findById(petId);
        if (petOpt.isEmpty()) return false;

        Optional<FavoritePet> favoritePet = favoritePetRepository.findByUsernameAndPet(username, petOpt.get());
        favoritePet.ifPresent(favoritePetRepository::delete);
        return favoritePet.isPresent();
    }

    public List<Pet> getFavoritePets(String username) {
        return favoritePetRepository.findByUsername(username)
                .stream()
                .map(FavoritePet::getPet)
                .toList();
    }
}
