package org.petify.funding.service.payment;

import org.petify.funding.dto.PaymentRequest;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.dto.WebhookEventDto;
import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;
import org.petify.funding.service.DonationStatusUpdateService;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.model.StripeObject;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
public class StripePaymentService implements PaymentProviderService {

    private final PaymentRepository paymentRepository;
    private final DonationRepository donationRepository;
    private final DonationStatusUpdateService statusUpdateService;

    @Value("${payment.stripe.webhook-secret}")
    private String webhookSecret;

    @Value("${app.webhook.base-url:http://localhost:8020}")
    private String webhookBaseUrl;

    @Override
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        try {
            log.info("Creating Stripe checkout session for donation {}", request.getDonationId());

            Donation donation = donationRepository.findById(request.getDonationId())
                    .orElseThrow(() -> new RuntimeException("Donation not found"));

            return createCheckoutSession(donation, request);

        } catch (StripeException e) {
            log.error("Stripe payment creation failed", e);
            throw new RuntimeException("Payment creation failed: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse getPaymentStatus(String externalId) {
        try {
            Session session = Session.retrieve(externalId);
            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            PaymentStatus oldStatus = payment.getStatus();
            PaymentStatus newStatus = mapStripeSessionStatus(session.getStatus());

            payment.setStatus(newStatus);
            Payment savedPayment = paymentRepository.save(payment);

            if (newStatus != oldStatus) {
                statusUpdateService.handlePaymentStatusChange(payment.getId(), newStatus);
            }

            return PaymentResponse.fromEntity(savedPayment);

        } catch (StripeException e) {
            log.error("Failed to get Stripe payment status", e);
            throw new RuntimeException("Failed to get payment status: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse cancelPayment(String externalId) {
        try {
            Session session = Session.retrieve(externalId);

            if (session.getPaymentIntent() != null) {
                PaymentIntent intent = PaymentIntent.retrieve(session.getPaymentIntent());
                if (intent.getStatus().equals("requires_payment_method")
                        || intent.getStatus().equals("requires_confirmation")) {
                    intent.cancel();
                }
            }

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            payment.setStatus(PaymentStatus.CANCELLED);
            Payment savedPayment = paymentRepository.save(payment);

            statusUpdateService.handlePaymentStatusChange(payment.getId(), PaymentStatus.CANCELLED);

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
            Session session = Session.retrieve(externalId);

            if (session.getPaymentIntent() == null) {
                throw new RuntimeException("No payment intent found for session");
            }

            PaymentIntent intent = PaymentIntent.retrieve(session.getPaymentIntent());

            com.stripe.param.RefundCreateParams refundParams =
                    com.stripe.param.RefundCreateParams.builder()
                            .setPaymentIntent(intent.getId())
                            .setAmount(convertToStripeAmount(amount))
                            .setReason(com.stripe.param.RefundCreateParams.Reason.REQUESTED_BY_CUSTOMER)
                            .build();

            com.stripe.model.Refund refund = com.stripe.model.Refund.create(refundParams);

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            PaymentStatus newStatus = refund.getAmount().equals(intent.getAmount())
                    ? PaymentStatus.REFUNDED
                    : PaymentStatus.PARTIALLY_REFUNDED;

            payment.setStatus(newStatus);
            Payment savedPayment = paymentRepository.save(payment);

            statusUpdateService.handlePaymentStatusChange(payment.getId(), newStatus);

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
                case "checkout.session.completed" -> {
                    log.info("Handling checkout session completed");
                    handleCheckoutSessionCompleted(event);
                }
                case "checkout.session.expired" -> {
                    log.info("Handling checkout session expired");
                    handleCheckoutSessionExpired(event);
                }
                default -> {
                    log.debug("Unhandled Stripe event type: {}", event.getType());
                }
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
        return Set.of(
                PaymentMethod.CARD,
                PaymentMethod.GOOGLE_PAY,
                PaymentMethod.APPLE_PAY,
                PaymentMethod.PRZELEWY24,
                PaymentMethod.BLIK,
                PaymentMethod.BANK_TRANSFER
        ).contains(method);
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

    private void handleCheckoutSessionCompleted(Event event) {
        try {
            Optional<StripeObject> stripeObjectOpt = event.getDataObjectDeserializer().getObject();

            Session session = null;

            if (stripeObjectOpt.isPresent() && stripeObjectOpt.get() instanceof Session) {
                session = (Session) stripeObjectOpt.get();
                log.info("Successfully deserialized session from event");
            } else {
                String sessionId = extractSessionIdFromRawData(event);
                if (sessionId != null) {
                    session = Session.retrieve(sessionId);
                    log.info("Successfully retrieved session from Stripe API: {}", sessionId);
                }
            }

            if (session == null) {
                log.error("Could not get session data for event: {}", event.getId());
                return;
            }

            processCompletedSession(session);

        } catch (Exception e) {
            log.error("Error processing checkout session completed event", e);
        }
    }

    private String extractSessionIdFromRawData(Event event) {
        try {
            StripeObject rawObject = event.getData().getObject();
            if (rawObject != null) {
                String objectString = rawObject.toString();
                java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\"id\"\\s*:\\s*\"(cs_test_[^\"]+)\"");
                java.util.regex.Matcher matcher = pattern.matcher(objectString);
                if (matcher.find()) {
                    return matcher.group(1);
                }
            }
        } catch (Exception e) {
            log.error("Error extracting session ID", e);
        }
        return null;
    }

    private void processCompletedSession(Session session) {
        String sessionId = session.getId();
        log.info("Processing completed session: {}", sessionId);

        Optional<Payment> paymentOpt = paymentRepository.findByExternalId(sessionId);

        if (paymentOpt.isEmpty()) {
            log.error("Payment NOT FOUND for session ID: '{}'", sessionId);
            return;
        }

        Payment payment = paymentOpt.get();
        log.info("Found payment: ID={}, ExternalID='{}', DonationID={}",
                payment.getId(), payment.getExternalId(), payment.getDonation().getId());

        if (payment.getStatus() == PaymentStatus.SUCCEEDED) {
            log.info("Payment {} already succeeded, skipping", payment.getId());
            return;
        }

        payment.setStatus(PaymentStatus.SUCCEEDED);
        paymentRepository.save(payment);

        statusUpdateService.handlePaymentStatusChange(payment.getId(), PaymentStatus.SUCCEEDED);

        log.info("Payment {} completed successfully for donation {}",
                payment.getId(), payment.getDonation().getId());
    }

    private void handleCheckoutSessionExpired(Event event) {
        try {
            Optional<StripeObject> stripeObjectOpt = event.getDataObjectDeserializer().getObject();

            Session session = null;

            if (stripeObjectOpt.isPresent() && stripeObjectOpt.get() instanceof Session) {
                session = (Session) stripeObjectOpt.get();
            } else {
                String sessionId = extractSessionIdFromRawData(event);
                if (sessionId != null) {
                    session = Session.retrieve(sessionId);
                }
            }

            if (session == null) {
                log.error("Could not get session data for expired event: {}", event.getId());
                return;
            }

            paymentRepository.findByExternalId(session.getId())
                    .ifPresent(payment -> {
                        if (payment.getStatus() != PaymentStatus.CANCELLED) {
                            payment.setStatus(PaymentStatus.CANCELLED);
                            paymentRepository.save(payment);
                            statusUpdateService.handlePaymentStatusChange(payment.getId(), PaymentStatus.CANCELLED);
                            log.info("Payment {} expired for donation {}",
                                    payment.getId(), payment.getDonation().getId());
                        }
                    });

        } catch (Exception e) {
            log.error("Error processing checkout session expired event", e);
        }
    }

    private PaymentResponse createCheckoutSession(Donation donation, PaymentRequest request) throws StripeException {

        SessionCreateParams.LineItem lineItem = SessionCreateParams.LineItem.builder()
                .setPriceData(
                        SessionCreateParams.LineItem.PriceData.builder()
                                .setCurrency(donation.getCurrency().name().toLowerCase())
                                .setProductData(
                                        SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                                .setName(buildProductName(donation))
                                                .setDescription(buildDescription(donation))
                                                .build()
                                )
                                .setUnitAmount(convertToStripeAmount(donation.getAmount()))
                                .build()
                )
                .setQuantity(1L)
                .build();

        SessionCreateParams.Builder sessionBuilder = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.PAYMENT)
                .addLineItem(lineItem)
                .putMetadata("donationId", String.valueOf(donation.getId()))
                .putMetadata("provider", PaymentProvider.STRIPE.getValue())
                .putMetadata("donationType", donation.getDonationType().name())
                .putMetadata("shelterId", String.valueOf(donation.getShelterId()));

        String successUrl = (request.getReturnUrl() != null && !request.getReturnUrl().trim().isEmpty())
                ? request.getReturnUrl() + "?session_id={CHECKOUT_SESSION_ID}&status=success"
                : webhookBaseUrl + "/payments/stripe-success?session_id={CHECKOUT_SESSION_ID}";

        String cancelUrl = (request.getCancelUrl() != null && !request.getCancelUrl().trim().isEmpty())
                ? request.getCancelUrl() + "?status=cancelled"
                : webhookBaseUrl + "/payments/stripe-cancel";

        sessionBuilder.setSuccessUrl(successUrl).setCancelUrl(cancelUrl);

        if (donation.getPetId() != null) {
            sessionBuilder.putMetadata("petId", String.valueOf(donation.getPetId()));
        }
        if (donation.getDonorUsername() != null) {
            sessionBuilder.putMetadata("donorUsername", donation.getDonorUsername());
        }

        sessionBuilder
                .addPaymentMethodType(SessionCreateParams.PaymentMethodType.CARD)
                .addPaymentMethodType(SessionCreateParams.PaymentMethodType.BLIK)
                .addPaymentMethodType(SessionCreateParams.PaymentMethodType.P24);

        configureBillingInfo(sessionBuilder, donation);

        Session session = Session.create(sessionBuilder.build());

        Payment payment = Payment.builder()
                .donation(donation)
                .provider(PaymentProvider.STRIPE)
                .externalId(session.getId())
                .status(PaymentStatus.PENDING)
                .amount(donation.getAmount())
                .currency(donation.getCurrency())
                .paymentMethod(PaymentMethod.CARD)
                .checkoutUrl(session.getUrl())
                .metadata(createMetadata(donation))
                .expiresAt(Instant.ofEpochSecond(session.getExpiresAt()))
                .build();

        Payment savedPayment = paymentRepository.save(payment);

        log.info("Stripe checkout session created with ID: {} for donation {}, checkout URL: {}",
                savedPayment.getId(), donation.getId(), session.getUrl());

        return PaymentResponse.fromEntity(savedPayment);
    }

    private void configureBillingInfo(SessionCreateParams.Builder sessionBuilder, Donation donation) {
        if (donation.getDonorUsername() != null && !donation.getDonorUsername().trim().isEmpty()) {

            if (donation.isDonorUsernameEmail()) {
                sessionBuilder.setCustomerEmail(donation.getDonorUsername());
            }

            sessionBuilder.setCustomerCreation(SessionCreateParams.CustomerCreation.ALWAYS);
        }
    }

    private String buildProductName(Donation donation) {
        if (donation instanceof MaterialDonation md && md.getItemName() != null) {
            return "Dotacja rzeczowa: " + md.getItemName();
        }
        return "Dotacja dla schroniska";
    }

    private Long convertToStripeAmount(BigDecimal amount) {
        return amount.multiply(new BigDecimal("100")).longValue();
    }

    private PaymentStatus mapStripeSessionStatus(String stripeStatus) {
        return switch (stripeStatus) {
            case "open" -> PaymentStatus.PENDING;
            case "complete" -> PaymentStatus.SUCCEEDED;
            case "expired" -> PaymentStatus.CANCELLED;
            default -> PaymentStatus.PENDING;
        };
    }

    private String buildDescription(Donation donation) {
        StringBuilder desc = new StringBuilder();

        if (donation.getDonationType() == DonationType.MONEY) {
            desc.append("Monetary donation");
        } else if (donation instanceof MaterialDonation md) {
            desc.append("Material donation: ").append(md.getItemName());
        }

        desc.append(" to animal shelter #").append(donation.getShelterId());

        if (donation.getPetId() != null) {
            desc.append(" for pet #").append(donation.getPetId());
        }

        return desc.toString();
    }

    private Map<String, String> createMetadata(Donation donation) {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("donationId", String.valueOf(donation.getId()));
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
}
