package org.petify.shelter.repository;

import org.petify.shelter.model.Adoption;
import org.petify.shelter.model.AdoptionStatus;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdoptionRepository extends JpaRepository<Adoption, Long> {
    boolean existsByPetIdAndUsername(Long petId, String username);

    List<Adoption> findByUsername(String username);

    List<Adoption> findByPet(Pet pet);

    List<Adoption> findByPetShelter(Shelter shelter);

    List<Adoption> findByPetAndAdoptionStatusAndIdNot(Pet pet, AdoptionStatus status, Long formId);
}
