package org.petify.funding.repository;

import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationType;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;

@Repository
public interface DonationRepository extends JpaRepository<Donation, Long> {

    Page<Donation> findAllByDonationType(DonationType donationType, Pageable pageable);

    Page<Donation> findByShelterId(Long shelterId, Pageable pageable);

    Page<Donation> findByPetId(Long petId, Pageable pageable);

    Page<Donation> findByDonorUsernameOrderByCreatedAtDesc(String donorUsername, Pageable pageable);

    Long countByShelterId(Long shelterId);

    @Query(
            "SELECT COALESCE(SUM(d.amount), 0) "
                    + "FROM Donation d "
                    + "WHERE d.shelterId = :shelterId "
                    + "  AND d.status = 'COMPLETED'"
    )
    BigDecimal sumAmountByShelterId(@Param("shelterId") Long shelterId);

    @Query(
            "SELECT COUNT(d) "
                    + "FROM Donation d "
                    + "WHERE d.shelterId = :shelterId "
                    + "  AND d.status = 'COMPLETED'"
    )
    Long countCompletedByShelterId(@Param("shelterId") Long shelterId);

    @Query(
            "SELECT COUNT(d) "
                    + "FROM Donation d "
                    + "WHERE d.shelterId = :shelterId "
                    + "  AND d.status = 'PENDING'"
    )
    Long countPendingByShelterId(@Param("shelterId") Long shelterId);

    @Query(
            "SELECT COALESCE(AVG(d.amount), 0) "
                    + "FROM Donation d "
                    + "WHERE d.shelterId = :shelterId "
                    + "  AND d.status = 'COMPLETED'"
    )
    BigDecimal averageAmountByShelterId(@Param("shelterId") Long shelterId);

    Page<Donation> findByFundraiserId(Long fundraiserId, Pageable pageable);

    Long countByFundraiserId(Long fundraiserId);

    @Query(
            "SELECT COALESCE(SUM(d.amount), 0) "
                    + "FROM Donation d "
                    + "WHERE d.fundraiser.id = :fundraiserId "
                    + "  AND d.status = 'COMPLETED'"
    )
    BigDecimal sumCompletedDonationsByFundraiserId(@Param("fundraiserId") Long fundraiserId);

    @Query(
            "SELECT COUNT(d) "
                    + "FROM Donation d "
                    + "WHERE d.fundraiser.id = :fundraiserId "
                    + "  AND d.status = 'COMPLETED'"
    )
    Long countCompletedDonationsByFundraiserId(@Param("fundraiserId") Long fundraiserId);

    @Query(
            "SELECT COUNT(DISTINCT d.donorUsername) "
                    + "FROM Donation d "
                    + "WHERE d.fundraiser.id = :fundraiserId "
                    + "  AND d.status = 'COMPLETED'"
    )
    Long countUniqueDonorsByFundraiserId(@Param("fundraiserId") Long fundraiserId);

    @Query(
            "SELECT COALESCE(SUM(d.amount), 0) "
                    + "FROM Donation d "
                    + "WHERE d.fundraiser.id = :fundraiserId "
                    + "  AND d.status = 'COMPLETED' "
                    + "  AND d.createdAt >= :dateAfter"
    )
    BigDecimal sumCompletedDonationsByFundraiserIdAndDateAfter(
            @Param("fundraiserId") Long fundraiserId,
            @Param("dateAfter") Instant dateAfter);

    @Query(
            "SELECT MAX(d.donatedAt) "
                    + "FROM Donation d "
                    + "WHERE d.shelterId = :shelterId "
                    + "  AND d.status = 'COMPLETED'"
    )
    Instant getLastDonationDateByShelterId(@Param("shelterId") Long shelterId);
}
