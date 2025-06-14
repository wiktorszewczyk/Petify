package org.petify.funding.repository;

import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.model.PaymentStatus;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByExternalId(String externalId);

    List<Payment> findByDonationId(Long donationId);

    Page<Payment> findByDonation_DonorUsernameOrderByCreatedAtDesc(String username, Pageable pageable);

    Page<Payment> findByDonation_DonorUsernameAndStatusOrderByCreatedAtDesc(
            String username, PaymentStatus status, Pageable pageable);

    @Query(
            "SELECT COUNT(p), "
                    + "COUNT(CASE WHEN p.status = 'SUCCEEDED' THEN 1 END), "
                    + "COUNT(CASE WHEN p.status = 'FAILED' THEN 1 END), "
                    + "SUM(CASE WHEN p.status = 'SUCCEEDED' THEN p.amount ELSE 0 END), "
                    + "SUM(CASE WHEN p.status = 'SUCCEEDED' THEN p.feeAmount ELSE 0 END) "
                    + "FROM Payment p WHERE p.createdAt BETWEEN :startDate AND :endDate"
    )
    List<Object[]> getPaymentStatistics(@Param("startDate") Instant startDate,
                                        @Param("endDate") Instant endDate);

    @Query(
            "SELECT COUNT(p), "
                    + "COUNT(CASE WHEN p.status = 'SUCCEEDED' THEN 1 END), "
                    + "SUM(CASE WHEN p.status = 'SUCCEEDED' THEN p.amount ELSE 0 END) "
                    + "FROM Payment p WHERE p.createdAt BETWEEN :startDate AND :endDate "
                    + "AND p.provider = :provider"
    )
    List<Object[]> getPaymentStatisticsByProvider(@Param("startDate") Instant startDate,
                                                  @Param("endDate") Instant endDate,
                                                  @Param("provider") PaymentProvider provider);

    @Query(
            "SELECT p.currency as currency, COUNT(p) as count, SUM(p.amount) as totalAmount "
                    + "FROM Payment p WHERE p.createdAt BETWEEN :startDate AND :endDate "
                    + "AND p.status = 'SUCCEEDED' GROUP BY p.currency"
    )
    Map<String, Object> getPaymentStatsByCurrency(@Param("startDate") Instant startDate,
                                                  @Param("endDate") Instant endDate);

    @Query(
            "SELECT p.paymentMethod as method, COUNT(p) as count, SUM(p.amount) as totalAmount "
                    + "FROM Payment p WHERE p.createdAt BETWEEN :startDate AND :endDate "
                    + "AND p.status = 'SUCCEEDED' GROUP BY p.paymentMethod"
    )
    Map<String, Object> getPaymentStatsByMethod(@Param("startDate") Instant startDate,
                                                @Param("endDate") Instant endDate);

    @Query(
            "SELECT p.feeAmount FROM Payment p "
                    + "WHERE p.createdAt BETWEEN :startDate AND :endDate "
                    + "AND p.provider = :provider AND p.status = 'SUCCEEDED'"
    )
    List<BigDecimal> getFeeAmountsByDateRangeAndProvider(@Param("startDate") Instant startDate,
                                                         @Param("endDate") Instant endDate,
                                                         @Param("provider") PaymentProvider provider);
}
