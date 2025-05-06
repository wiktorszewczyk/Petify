package org.petify.shelter.repository;

import org.petify.shelter.model.PetImage;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PetImageRepository extends JpaRepository<PetImage, Long> {
    List<PetImage> findAllByPetId(Long petId);
}