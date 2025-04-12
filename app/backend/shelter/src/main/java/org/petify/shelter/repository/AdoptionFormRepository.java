package org.petify.shelter.repository;

import org.petify.shelter.model.AdoptionForm;
import org.petify.shelter.model.AdoptionStatus;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdoptionFormRepository extends JpaRepository<AdoptionForm, Long> {
    boolean existsByPetIdAndUserId(Long petId, Integer userId);
    List<AdoptionForm> findByUserId(Integer userId);
    List<AdoptionForm> findByPet(Pet pet);
    List<AdoptionForm> findByPetShelter(Shelter shelter);
    List<AdoptionForm> findByPetAndAdoptionStatusAndIdNot(Pet pet, AdoptionStatus status, Long formId);
}