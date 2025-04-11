package org.petify.shelter.repository;

import org.petify.shelter.model.AdoptionForm;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AdoptionFormRepository extends JpaRepository<AdoptionForm, Long> {
}