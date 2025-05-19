package org.petify.funding.service;

import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.net.Webhook;
import com.stripe.param.PaymentIntentCreateParams;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final DonationRepository donationRepo;
    private final PaymentRepository paymentRepo;

    @Value("${stripe.webhook-secret}")
    private String webhookSecret;

    @Transactional
    public String createPaymentIntent(Long donationId) throws StripeException {
        Donation donation = donationRepo.findById(donationId)
                .orElseThrow(() -> new IllegalArgumentException("Donation not found: " + donationId));

        long amountInCents = donation.getAmount()
                .movePointRight(2)
                .longValue();

        PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                .setAmount(amountInCents)
                .setCurrency(donation.getCurrency().toLowerCase())
                .putAllMetadata(Map.of("donationId", donationId.toString()))
                .build();

        PaymentIntent intent = PaymentIntent.create(params);

        Payment payment = Payment.builder()
                .donation(donation)
                .provider("STRIPE")
                .externalId(intent.getId())
                .status(PaymentStatus.PENDING)
                .amount(donation.getAmount())
                .currency(donation.getCurrency())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        paymentRepo.save(payment);
        donation.getPayments().add(payment);
        donation.setStatus(DonationStatus.PENDING);

        return intent.getClientSecret();
    }

    @Transactional
    public void handleWebhook(String payload, String sigHeader) throws SignatureVerificationException {
        Event event = Webhook.constructEvent(payload, sigHeader, webhookSecret);
        if ("payment_intent.succeeded".equals(event.getType())) {
            PaymentIntent pi = (PaymentIntent) event
                    .getDataObjectDeserializer()
                    .getObject()
                    .orElseThrow();
            paymentRepo.findByExternalId(pi.getId()).ifPresent(p -> {
                p.setStatus(PaymentStatus.SUCCEEDED);
                p.setUpdatedAt(Instant.now());
                Donation d = p.getDonation();
                d.setStatus(DonationStatus.COMPLETED);
                donationRepo.save(d);
            });

        } else if ("payment_intent.payment_failed".equals(event.getType())) {
            PaymentIntent pi = (PaymentIntent) event
                    .getDataObjectDeserializer()
                    .getObject()
                    .orElseThrow();
            paymentRepo.findByExternalId(pi.getId()).ifPresent(p -> {
                p.setStatus(PaymentStatus.FAILED);
                p.setUpdatedAt(Instant.now());
                paymentRepo.save(p);

                Donation d = p.getDonation();
                // jeżeli żadna z prób nie jest SUCCEEDED → darowizna też FAILURE
                boolean anySuccess = d.getPayments().stream()
                        .anyMatch(x -> x.getStatus() == PaymentStatus.SUCCEEDED);
                if (!anySuccess) {
                    d.setStatus(DonationStatus.FAILED);
                    donationRepo.save(d);
                }
            });
        }
    }
}
