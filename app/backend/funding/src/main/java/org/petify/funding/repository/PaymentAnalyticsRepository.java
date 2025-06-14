package org.petify.funding.repository;

import org.petify.funding.model.PaymentAnalytics;
import org.petify.funding.model.PaymentProvider;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentAnalyticsRepository extends JpaRepository<PaymentAnalytics, Long> {

    Optional<PaymentAnalytics> findByDateAndProvider(LocalDate date, PaymentProvider provider);

    List<PaymentAnalytics> findByDateBetween(LocalDate startDate, LocalDate endDate);

    List<PaymentAnalytics> findByDateBetweenAndProvider(LocalDate startDate, LocalDate endDate,
                                                        PaymentProvider provider);
}
