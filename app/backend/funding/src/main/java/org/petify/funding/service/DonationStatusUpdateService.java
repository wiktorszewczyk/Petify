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
        log.info("Processing payment status change for payment {} to {}", paymentId, newStatus);

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found: " + paymentId));

        Donation donation = payment.getDonation();
        log.info("Found donation {} with current status: {}", donation.getId(), donation.getStatus());

        if (newStatus == PaymentStatus.SUCCEEDED) {
            if (donation.getStatus() != DonationStatus.COMPLETED) {
                log.info("Payment succeeded - updating donation {} status to COMPLETED", donation.getId());
                updateDonationStatus(donation.getId(), DonationStatus.COMPLETED);
            } else {
                log.info("Donation {} already completed", donation.getId());
            }
        } else if (newStatus == PaymentStatus.FAILED || newStatus == PaymentStatus.CANCELLED) {
            log.info("Payment failed/cancelled for donation {}", donation.getId());

            donation = donationRepository.findById(donation.getId())
                    .orElseThrow(() -> new RuntimeException("Donation not found"));

            if (donation.hasReachedMaxPaymentAttempts() && !donation.hasSuccessfulPayment()) {
                log.info("Max payment attempts reached - marking donation {} as FAILED", donation.getId());
                updateDonationStatus(donation.getId(), DonationStatus.FAILED);
            }
        }
    }

    @Transactional
    public void updateDonationStatus(Long donationId, DonationStatus newStatus) {
        log.info("Updating donation {} status to {}", donationId, newStatus);

        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new RuntimeException("Donation not found: " + donationId));

        DonationStatus oldStatus = donation.getStatus();
        donation.setStatus(newStatus);

        if (newStatus == DonationStatus.COMPLETED && oldStatus != DonationStatus.COMPLETED
                && donation.getDonatedAt() == null) {
            donation.setDonatedAt(java.time.Instant.now());
            log.info("Set donatedAt for donation {}", donationId);
        }

        Donation saved = donationRepository.save(donation);
        log.info("Donation {} status updated from {} to {} (saved status: {})",
                donationId, oldStatus, newStatus, saved.getStatus());
    }
}
