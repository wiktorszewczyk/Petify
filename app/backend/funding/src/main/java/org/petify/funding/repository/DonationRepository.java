package org.petify.funding.repository;

import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationType;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DonationRepository
        extends JpaRepository<Donation, Long> {

    Page<Donation> findAllByDonationType(
            DonationType donationType,
            Pageable pageable
    );

    Page<Donation> findByShelterId(
            Long shelterId,
            Pageable pageable
    );

    Page<Donation> findByPetId(
            Long petId,
            Pageable pageable
    );
}
