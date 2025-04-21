package org.petify.funding.repository;

import org.petify.funding.model.Donation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DonationRepository extends JpaRepository<Donation, Long> {
    List<Donation> findByShelterId(Long shelterId);
    List<Donation> findByPetId(Long petId);
}
