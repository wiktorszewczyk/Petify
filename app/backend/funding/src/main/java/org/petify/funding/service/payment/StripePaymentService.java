package org.petify.funding.service.payment;

import jakarta.validation.constraints.NotNull;
import org.petify.funding.dto.PaymentRequest;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.dto.WebhookEventDto;
import org.petify.funding.model.*;
import org.petify.funding.model.Currency;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.net.Webhook;
import com.stripe.param.PaymentIntentCreateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class StripePaymentService implements PaymentProviderService {

    private final PaymentRepository paymentRepository;
    private final DonationRepository donationRepository;

    @Value("${payment.stripe.webhook-secret}")
    private String webhookSecret;

    @Override
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        try {
            log.info("Creating Stripe payment for donation {}", request.getDonationId());

            Donation donation = donationRepository.findById(request.getDonationId())
                    .orElseThrow(() -> new RuntimeException("Donation not found"));

            PaymentIntentCreateParams.Builder paramsBuilder = PaymentIntentCreateParams.builder()
                    .setAmount(convertToStripeAmount(request.getAmount(), request.getCurrency()))
                    .setCurrency(request.getCurrency().name().toLowerCase())
                    .putMetadata("donationId", String.valueOf(request.getDonationId()))
                    .putMetadata("provider", PaymentProvider.STRIPE.getValue())
                    .putMetadata("donationType", donation.getDonationType().name())
                    .putMetadata("shelterId", String.valueOf(donation.getShelterId()));

            if (request.getDescription() != null) {
                paramsBuilder.setDescription(request.getDescription());
            } else {
                String description = String.format("Donation to shelter #%d", donation.getShelterId());
                if (donation.getPetId() != null) {
                    description += String.format(" for pet #%d", donation.getPetId());
                }
                paramsBuilder.setDescription(description);
            }

            configurePaymentMethods(paramsBuilder, request);

            PaymentIntent intent = PaymentIntent.create(paramsBuilder.build());

            Payment payment = Payment.builder()
                    .donation(donation)
                    .provider(PaymentProvider.STRIPE)
                    .externalId(intent.getId())
                    .status(mapStripeStatus(intent.getStatus()))
                    .amount(request.getAmount())
                    .currency(request.getCurrency())
                    .paymentMethod(determinePaymentMethod(request))
                    .clientSecret(intent.getClientSecret())
                    .metadata(createMetadata(request, donation))
                    .expiresAt(Instant.now().plusSeconds(3600))
                    .build();

            Payment savedPayment = paymentRepository.save(payment);

            log.info("Stripe payment created with ID: {} for donation {}",
                    savedPayment.getId(), donation.getId());
            return PaymentResponse.fromEntity(savedPayment);

        } catch (StripeException e) {
            log.error("Stripe payment creation failed", e);
            throw new RuntimeException("Payment creation failed: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse getPaymentStatus(String externalId) {
        try {
            PaymentIntent intent = PaymentIntent.retrieve(externalId);
            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            PaymentStatus oldStatus = payment.getStatus();
            PaymentStatus newStatus = mapStripeStatus(intent.getStatus());

            payment.setStatus(newStatus);

            if (intent.getLastPaymentError() != null) {
                payment.setFailureReason(intent.getLastPaymentError().getMessage());
                payment.setFailureCode(intent.getLastPaymentError().getCode());
            }

            if (newStatus == PaymentStatus.SUCCEEDED && oldStatus != PaymentStatus.SUCCEEDED) {
                updateDonationStatus(payment.getDonation(), DonationStatus.COMPLETED);
            }

            Payment savedPayment = paymentRepository.save(payment);
            return PaymentResponse.fromEntity(savedPayment);

        } catch (StripeException e) {
            log.error("Failed to get Stripe payment status", e);
            throw new RuntimeException("Failed to get payment status: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse cancelPayment(String externalId) {
        try {
            PaymentIntent intent = PaymentIntent.retrieve(externalId);
            PaymentIntent cancelledIntent = intent.cancel();

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            payment.setStatus(PaymentStatus.CANCELLED);
            Payment savedPayment = paymentRepository.save(payment);

            log.info("Stripe payment {} cancelled", payment.getId());
            return PaymentResponse.fromEntity(savedPayment);

        } catch (StripeException e) {
            log.error("Failed to cancel Stripe payment", e);
            throw new RuntimeException("Failed to cancel payment: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse refundPayment(String externalId, BigDecimal amount) {
        try {
            PaymentIntent intent = PaymentIntent.retrieve(externalId);

            com.stripe.param.RefundCreateParams refundParams =
                    com.stripe.param.RefundCreateParams.builder()
                            .setPaymentIntent(intent.getId())
                            .setAmount(convertToStripeAmount(amount,
                                    Currency.valueOf(intent.getCurrency().toUpperCase())))
                            .setReason(com.stripe.param.RefundCreateParams.Reason.REQUESTED_BY_CUSTOMER)
                            .build();

            com.stripe.model.Refund refund = com.stripe.model.Refund.create(refundParams);

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            if (refund.getAmount().equals(intent.getAmount())) {
                payment.setStatus(PaymentStatus.REFUNDED);
                updateDonationStatus(payment.getDonation(), DonationStatus.FAILED);
            } else {
                payment.setStatus(PaymentStatus.PARTIALLY_REFUNDED);
            }

            Payment savedPayment = paymentRepository.save(payment);
            log.info("Stripe payment {} refunded (amount: {})", payment.getId(), amount);
            return PaymentResponse.fromEntity(savedPayment);

        } catch (StripeException e) {
            log.error("Failed to refund Stripe payment", e);
            throw new RuntimeException("Failed to refund payment: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional
    public void handleWebhook(String payload, String signature) {
        try {
            Event event = Webhook.constructEvent(payload, signature, webhookSecret);

            log.info("Processing Stripe webhook event: {} ({})", event.getType(), event.getId());

            switch (event.getType()) {
                case "payment_intent.succeeded":
                    handlePaymentSucceeded(event);
                    break;
                case "payment_intent.payment_failed":
                    handlePaymentFailed(event);
                    break;
                case "payment_intent.canceled":
                    handlePaymentCanceled(event);
                    break;
                case "payment_intent.processing":
                    handlePaymentProcessing(event);
                    break;
                default:
                    log.debug("Unhandled Stripe event type: {}", event.getType());
            }

        } catch (SignatureVerificationException e) {
            log.error("Invalid Stripe webhook signature", e);
            throw new RuntimeException("Invalid webhook signature", e);
        }
    }

    @Override
    public WebhookEventDto parseWebhookEvent(String payload, String signature) {
        try {
            Event event = Webhook.constructEvent(payload, signature, webhookSecret);

            return WebhookEventDto.builder()
                    .eventId(event.getId())
                    .eventType(event.getType())
                    .provider(PaymentProvider.STRIPE.getValue())
                    .receivedAt(Instant.now())
                    .processed(false)
                    .build();

        } catch (SignatureVerificationException e) {
            throw new RuntimeException("Invalid webhook signature", e);
        }
    }

    @Override
    public boolean supportsPaymentMethod(PaymentMethod method) {
        return Set.of(PaymentMethod.CARD, PaymentMethod.GOOGLE_PAY,
                        PaymentMethod.APPLE_PAY, PaymentMethod.PAYPAL)
                .contains(method);
    }

    @Override
    public boolean supportsCurrency(Currency currency) {
        return Set.of(Currency.USD, Currency.EUR, Currency.GBP, Currency.PLN)
                .contains(currency);
    }

    @Override
    public BigDecimal calculateFee(BigDecimal amount, Currency currency) {
        BigDecimal percentageFee = amount.multiply(new BigDecimal("0.029"));
        BigDecimal fixedFee = switch (currency) {
            case USD -> new BigDecimal("0.30");
            case EUR -> new BigDecimal("0.25");
            case GBP -> new BigDecimal("0.20");
            case PLN -> new BigDecimal("1.20");
        };
        return percentageFee.add(fixedFee);
    }

    private Long convertToStripeAmount(BigDecimal amount, @NotNull Currency currency) {
        return amount.multiply(new BigDecimal("100")).longValue();
    }

    private PaymentStatus mapStripeStatus(String stripeStatus) {
        return switch (stripeStatus) {
            case "requires_payment_method", "requires_confirmation", "requires_action" -> PaymentStatus.PENDING;
            case "processing" -> PaymentStatus.PROCESSING;
            case "succeeded" -> PaymentStatus.SUCCEEDED;
            case "canceled" -> PaymentStatus.CANCELLED;
            default -> PaymentStatus.FAILED;
        };
    }

    private PaymentMethod determinePaymentMethod(PaymentRequest request) {
        if (request.getPreferredMethod() != null) {
            return request.getPreferredMethod();
        }
        return PaymentMethod.CARD;
    }

    private Map<String, String> createMetadata(PaymentRequest request, Donation donation) {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("donationId", String.valueOf(request.getDonationId()));
        metadata.put("provider", PaymentProvider.STRIPE.getValue());
        metadata.put("donationType", donation.getDonationType().name());
        metadata.put("shelterId", String.valueOf(donation.getShelterId()));

        if (donation.getPetId() != null) {
            metadata.put("petId", String.valueOf(donation.getPetId()));
        }
        if (donation.getDonorUsername() != null) {
            metadata.put("donorUsername", donation.getDonorUsername());
        }

        return metadata;
    }

    private void configurePaymentMethods(PaymentIntentCreateParams.Builder builder,
                                         PaymentRequest request) {
        List<String> paymentMethodTypes = new ArrayList<>();
        paymentMethodTypes.add("card");

        if (request.getCurrency() == Currency.USD || request.getCurrency() == Currency.EUR) {
            paymentMethodTypes.add("paypal");
        }

        if (request.getCurrency() == Currency.USD) {
            paymentMethodTypes.add("us_bank_account");
        }

        builder.addAllPaymentMethodType(paymentMethodTypes);
    }

    private void handlePaymentSucceeded(Event event) {
        PaymentIntent paymentIntent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject().orElseThrow();

        paymentRepository.findByExternalId(paymentIntent.getId())
                .ifPresent(payment -> {
                    payment.setStatus(PaymentStatus.SUCCEEDED);

                    paymentRepository.save(payment);

                    updateDonationStatus(payment.getDonation(), DonationStatus.COMPLETED);

                    log.info("Stripe payment {} succeeded for donation {}",
                            payment.getId(), payment.getDonation().getId());
                });
    }

    private void handlePaymentFailed(Event event) {
        PaymentIntent paymentIntent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject().orElseThrow();

        paymentRepository.findByExternalId(paymentIntent.getId())
                .ifPresent(payment -> {
                    payment.setStatus(PaymentStatus.FAILED);

                    if (paymentIntent.getLastPaymentError() != null) {
                        payment.setFailureReason(paymentIntent.getLastPaymentError().getMessage());
                        payment.setFailureCode(paymentIntent.getLastPaymentError().getCode());
                    }

                    paymentRepository.save(payment);

                    boolean hasOtherPendingPayments = payment.getDonation().getPayments().stream()
                            .anyMatch(p -> !p.equals(payment) &&
                                    (p.getStatus() == PaymentStatus.PENDING ||
                                            p.getStatus() == PaymentStatus.PROCESSING));

                    if (!hasOtherPendingPayments) {
                        updateDonationStatus(payment.getDonation(), DonationStatus.FAILED);
                    }

                    log.info("Stripe payment {} failed for donation {}",
                            payment.getId(), payment.getDonation().getId());
                });
    }

    private void handlePaymentCanceled(Event event) {
        PaymentIntent paymentIntent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject().orElseThrow();

        paymentRepository.findByExternalId(paymentIntent.getId())
                .ifPresent(payment -> {
                    payment.setStatus(PaymentStatus.CANCELLED);
                    paymentRepository.save(payment);

                    log.info("Stripe payment {} canceled for donation {}",
                            payment.getId(), payment.getDonation().getId());
                });
    }

    private void handlePaymentProcessing(Event event) {
        PaymentIntent paymentIntent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject().orElseThrow();

        paymentRepository.findByExternalId(paymentIntent.getId())
                .ifPresent(payment -> {
                    payment.setStatus(PaymentStatus.PROCESSING);
                    paymentRepository.save(payment);

                    log.info("Stripe payment {} is processing for donation {}",
                            payment.getId(), payment.getDonation().getId());
                });
    }

    private void updateDonationStatus(Donation donation, DonationStatus newStatus) {
        try {
            donation.setStatus(newStatus);
            if (newStatus == DonationStatus.COMPLETED) {
                donation.setCompletedAt(Instant.now());
                donation.calculateTotalFees();
            }
            donationRepository.save(donation);

            log.info("Updated donation {} status to {}", donation.getId(), newStatus);
        } catch (Exception e) {
            log.error("Failed to update donation status", e);
        }
    }
}