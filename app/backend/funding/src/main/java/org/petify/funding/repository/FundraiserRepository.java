package org.petify.funding.repository;

import org.petify.funding.model.Fundraiser;
import org.petify.funding.model.FundraiserStatus;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FundraiserRepository extends JpaRepository<Fundraiser, Long> {

    Page<Fundraiser> findByShelterId(Long shelterId, Pageable pageable);

    Optional<Fundraiser> findByShelterIdAndIsMainTrue(Long shelterId);

    @Query(
            "SELECT f FROM Fundraiser f WHERE f.status = :status AND f.endDate IS NULL"
                    + " OR f.endDate > CURRENT_TIMESTAMP")
    Page<Fundraiser> findActiveByStatus(@Param("status") FundraiserStatus status, Pageable pageable);

    boolean existsByShelterIdAndIsMainTrue(Long shelterId);
}
