package org.petify.funding.service;

import org.petify.funding.model.Donation;
import org.petify.funding.model.Payment;
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

@RequiredArgsConstructor
@Service
public class PaymentService {

    private final DonationRepository donationRepo;
    private final PaymentRepository paymentRepo;

    @Value("${stripe.webhook-secret}")
    private String webhookSecret;

    @Transactional
    public String createPaymentIntent(Long donationId)
            throws StripeException {
        Donation d = donationRepo.findById(donationId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Donation not found: " + donationId
                        )
                );

        long amountInCents = d.getAmount()
                .movePointRight(2)
                .longValue();

        PaymentIntentCreateParams params =
                PaymentIntentCreateParams.builder()
                        .setAmount(amountInCents)
                        .setCurrency(d.getCurrency().toLowerCase())
                        .putAllMetadata(
                                Map.of("donationId", donationId.toString())
                        )
                        .build();

        PaymentIntent intent = PaymentIntent.create(params);

        Payment p = Payment.builder()
                .provider("STRIPE")
                .externalId(intent.getId())
                .status(intent.getStatus().toUpperCase())
                .amount(d.getAmount())
                .currency(d.getCurrency())
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        paymentRepo.save(p);

        return intent.getClientSecret();
    }

    @Transactional
    public void handleWebhook(
            String payload,
            String sigHeader
    ) throws SignatureVerificationException {
        Event event = Webhook.constructEvent(
                payload,
                sigHeader,
                webhookSecret
        );

        if ("payment_intent.succeeded".equals(event.getType())) {
            PaymentIntent pi = (PaymentIntent)
                    event.getDataObjectDeserializer()
                            .getObject()
                            .orElseThrow();
            paymentRepo.findByExternalId(pi.getId())
                    .ifPresent(p -> {
                        p.setStatus("SUCCEEDED");
                        p.setUpdatedAt(Instant.now());
                        paymentRepo.save(p);
                    });
        } else if ("payment_intent.payment_failed"
                .equals(event.getType())) {
            PaymentIntent pi = (PaymentIntent)
                    event.getDataObjectDeserializer()
                            .getObject()
                            .orElseThrow();
            paymentRepo.findByExternalId(pi.getId())
                    .ifPresent(p -> {
                        p.setStatus("FAILED");
                        p.setUpdatedAt(Instant.now());
                        paymentRepo.save(p);
                    });
        }
    }
}
