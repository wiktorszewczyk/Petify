package org.petify.shelter.repository;

import org.petify.shelter.model.FavoritePet;
import org.petify.shelter.model.Pet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoritePetRepository extends JpaRepository<FavoritePet, Long> {
    List<FavoritePet> findByUsername(String username);

    Optional<FavoritePet> findByUsernameAndPet(String username, Pet pet);
}