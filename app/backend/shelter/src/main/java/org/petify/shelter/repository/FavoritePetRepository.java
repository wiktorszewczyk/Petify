package org.petify.shelter.repository;

import org.petify.shelter.enums.MatchType;
import org.petify.shelter.model.FavoritePet;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoritePetRepository extends JpaRepository<FavoritePet, Long> {
    List<FavoritePet> findByUsername(String username);

    Optional<FavoritePet> findByUsernameAndStatus(String username, MatchType status);

    Optional<FavoritePet> findByUsernameAndPetId(String username, Long petId);
}
