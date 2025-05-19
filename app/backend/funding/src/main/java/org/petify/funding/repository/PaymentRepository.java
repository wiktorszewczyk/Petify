package org.petify.funding.repository;

import org.petify.funding.model.Payment;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PaymentRepository
        extends JpaRepository<Payment, Long> {

    Optional<Payment> findByExternalId(String externalId);
}
