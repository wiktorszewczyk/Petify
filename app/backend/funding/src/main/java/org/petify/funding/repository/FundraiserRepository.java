package org.petify.funding.repository;

import org.petify.funding.model.Fundraiser;
import org.petify.funding.model.FundraiserStatus;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FundraiserRepository extends JpaRepository<Fundraiser, Long> {

    Page<Fundraiser> findByShelterId(Long shelterId, Pageable pageable);

    List<Fundraiser> findByShelterId(Long shelterId);

    Page<Fundraiser> findByShelterIdAndStatus(Long shelterId, FundraiserStatus status, Pageable pageable);

    Optional<Fundraiser> findByShelterIdAndIsMainTrue(Long shelterId);

    @Query(
            "SELECT f FROM Fundraiser f WHERE f.status = :status AND f.endDate IS NULL"
                    + " OR f.endDate > CURRENT_TIMESTAMP")
    Page<Fundraiser> findActiveByStatus(@Param("status") FundraiserStatus status, Pageable pageable);

    @Query(
            "SELECT f FROM Fundraiser f WHERE f.shelterId = :shelterId AND f.status = 'ACTIVE'"
                    + " AND (f.endDate IS NULL OR f.endDate > CURRENT_TIMESTAMP)"
    )
    List<Fundraiser> findActiveByShelter(@Param("shelterId") Long shelterId);

    boolean existsByShelterIdAndIsMainTrue(Long shelterId);
}
