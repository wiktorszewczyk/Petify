package org.petify.funding.service;

import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DonationStatusUpdateService {

    private final DonationRepository donationRepository;
    private final PaymentRepository paymentRepository;

    @Transactional
    public void handlePaymentStatusChange(Long paymentId, PaymentStatus newStatus) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found: " + paymentId));

        Donation donation = payment.getDonation();

        if (newStatus == PaymentStatus.SUCCEEDED && !donation.hasSuccessfulPayment()) {
            updateDonationStatus(donation.getId(), DonationStatus.COMPLETED);
        } else if (newStatus == PaymentStatus.FAILED || newStatus == PaymentStatus.CANCELLED) {

            if (donation.hasReachedMaxPaymentAttempts() && !donation.hasSuccessfulPayment()) {
                updateDonationStatus(donation.getId(), DonationStatus.FAILED);
                log.info("Donation {} marked as failed after reaching max payment attempts", donation.getId());
            }
        }
    }

    @Transactional
    public void updateDonationStatus(Long donationId, DonationStatus newStatus) {
        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new RuntimeException("Donation not found: " + donationId));

        DonationStatus oldStatus = donation.getStatus();
        donation.setStatus(newStatus);

        if (newStatus == DonationStatus.COMPLETED && oldStatus != DonationStatus.COMPLETED) {
            donation.setCompletedAt(java.time.Instant.now());
        }

        donationRepository.save(donation);
        log.info("Donation {} status updated from {} to {}", donationId, oldStatus, newStatus);
    }
}