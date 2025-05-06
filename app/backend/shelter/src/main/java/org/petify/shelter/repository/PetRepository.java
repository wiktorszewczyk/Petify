package org.petify.shelter.repository;

import org.petify.shelter.model.Pet;
import org.petify.shelter.enums.PetType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PetRepository extends JpaRepository<Pet, Long> {
    Optional<List<Pet>> findByShelterId(Long shelterId);
}