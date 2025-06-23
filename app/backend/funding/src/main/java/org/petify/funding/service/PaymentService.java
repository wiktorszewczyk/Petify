package org.petify.funding.service;

import org.petify.funding.dto.PaymentChoiceRequest;
import org.petify.funding.dto.PaymentFeeCalculation;
import org.petify.funding.dto.PaymentInitializationResponse;
import org.petify.funding.dto.PaymentMethodOption;
import org.petify.funding.dto.PaymentProviderOption;
import org.petify.funding.dto.PaymentRequest;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.dto.PaymentUiConfig;
import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;
import org.petify.funding.service.payment.PaymentProviderFactory;
import org.petify.funding.service.payment.PaymentProviderService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final DonationRepository donationRepository;
    private final PaymentProviderFactory providerFactory;
    private final DonationStatusUpdateService statusUpdateService;

    @Transactional
    public void handleStripeWebhook(String payload, String signature) {
        PaymentProviderService stripeService = providerFactory.getProvider(PaymentProvider.STRIPE);
        stripeService.handleWebhook(payload, signature);
    }

    @Transactional
    public void handlePayUWebhook(String payload, String signature) {
        PaymentProviderService payuService = providerFactory.getProvider(PaymentProvider.PAYU);
        payuService.handleWebhook(payload, signature);
    }

    @Transactional
    public PaymentResponse cancelPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (!canCancelPayment(payment)) {
            throw new RuntimeException("Payment cannot be cancelled in current state: " + payment.getStatus());
        }

        PaymentProviderService providerService = providerFactory.getProvider(payment.getProvider());
        final PaymentResponse response = providerService.cancelPayment(payment.getExternalId());

        payment.setStatus(PaymentStatus.CANCELLED);
        paymentRepository.save(payment);

        statusUpdateService.handlePaymentStatusChange(paymentId, PaymentStatus.CANCELLED);

        log.info("Payment {} cancelled successfully", paymentId);
        return response;
    }

    public List<PaymentProviderOption> getAvailablePaymentOptions(BigDecimal amount, String userLocation) {
        List<PaymentProviderOption> options = new ArrayList<>();

        if ("PL".equals(userLocation)) {
            PaymentFeeCalculation payuFees = calculatePaymentFee(amount, PaymentProvider.PAYU);

            options.add(PaymentProviderOption.builder()
                    .provider(PaymentProvider.PAYU)
                    .displayName("PayU")
                    .recommended(true)
                    .fees(payuFees)
                    .supportedMethods(Arrays.asList(
                            PaymentMethodOption.builder()
                                    .method(PaymentMethod.BLIK)
                                    .displayName("BLIK")
                                    .requiresAdditionalInfo(true)
                                    .build(),
                            PaymentMethodOption.builder()
                                    .method(PaymentMethod.CARD)
                                    .displayName("Karta płatnicza")
                                    .requiresAdditionalInfo(false)
                                    .build(),
                            PaymentMethodOption.builder()
                                    .method(PaymentMethod.BANK_TRANSFER)
                                    .displayName("Przelew bankowy")
                                    .requiresAdditionalInfo(false)
                                    .build(),
                            PaymentMethodOption.builder()
                                    .method(PaymentMethod.GOOGLE_PAY)
                                    .displayName("Płatność Google Pay")
                                    .requiresAdditionalInfo(false)
                                    .build()
                    ))
                    .build());
        }

        PaymentFeeCalculation stripeFees = calculatePaymentFee(amount, PaymentProvider.STRIPE);

        options.add(PaymentProviderOption.builder()
                .provider(PaymentProvider.STRIPE)
                .displayName("Stripe")
                .recommended(false)
                .fees(stripeFees)
                .supportedMethods(Arrays.asList(
                        PaymentMethodOption.builder()
                                .method(PaymentMethod.CARD)
                                .displayName("Credit/Debit Card")
                                .requiresAdditionalInfo(false)
                                .build(),
                        PaymentMethodOption.builder()
                                .method(PaymentMethod.GOOGLE_PAY)
                                .displayName("Google Pay")
                                .requiresAdditionalInfo(false)
                                .build(),
                        PaymentMethodOption.builder()
                                .method(PaymentMethod.APPLE_PAY)
                                .displayName("Apple Pay")
                                .requiresAdditionalInfo(false)
                                .build()
                ))
                .build());

        markLowestFee(options);

        return options;
    }

    @Transactional
    public PaymentInitializationResponse initializePayment(Long donationId, PaymentChoiceRequest request) {
        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new RuntimeException("Donation not found"));

        validateDonationCanAcceptPayment(donation);

        donation.incrementPaymentAttempts();

        if (donation.getStatus() == DonationStatus.PENDING) {
            donation.setStatus(DonationStatus.PENDING);
            donationRepository.save(donation);
        }

        PaymentProviderService providerService = providerFactory.getProvider(request.getProvider());

        PaymentRequest paymentRequest = PaymentRequest.builder()
                .donationId(donationId)
                .preferredProvider(request.getProvider())
                .preferredMethod(request.getMethod())
                .returnUrl(request.getReturnUrl())
                .cancelUrl(request.getCancelUrl())
                .blikCode(request.getBlikCode())
                .build();

        PaymentResponse payment = providerService.createPayment(paymentRequest);

        PaymentUiConfig uiConfig = buildUiConfig(request.getProvider(), payment);

        return PaymentInitializationResponse.builder()
                .payment(payment)
                .uiConfig(uiConfig)
                .build();
    }

    public PaymentFeeCalculation calculatePaymentFee(BigDecimal amount, PaymentProvider provider) {
        PaymentProviderService providerService = providerFactory.getProvider(provider);
        BigDecimal fee = providerService.calculateFee(amount, Currency.PLN);
        BigDecimal netAmount = amount.subtract(fee);

        return PaymentFeeCalculation.builder()
                .grossAmount(amount)
                .feeAmount(fee)
                .netAmount(netAmount)
                .provider(provider)
                .currency(Currency.PLN)
                .feePercentage(fee.divide(amount, 4, RoundingMode.HALF_UP)
                        .multiply(new BigDecimal("100")))
                .build();
    }

    public PaymentResponse getPaymentById(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return PaymentResponse.fromEntity(payment);
    }

    public List<PaymentResponse> getPaymentsByDonation(Long donationId) {
        List<Payment> payments = paymentRepository.findByDonationId(donationId);
        return payments.stream()
                .map(PaymentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public PaymentResponse refundPayment(Long paymentId, BigDecimal amount) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (payment.getStatus() != PaymentStatus.SUCCEEDED) {
            throw new RuntimeException("Can only refund successful payments");
        }

        BigDecimal refundAmount = amount != null ? amount : payment.getAmount();

        if (refundAmount.compareTo(payment.getAmount()) > 0) {
            throw new RuntimeException("Refund amount cannot exceed payment amount");
        }

        PaymentProviderService providerService = providerFactory.getProvider(payment.getProvider());
        final PaymentResponse response = providerService.refundPayment(payment.getExternalId(), refundAmount);

        PaymentStatus newStatus = refundAmount.compareTo(payment.getAmount()) == 0
                ? PaymentStatus.REFUNDED
                : PaymentStatus.PARTIALLY_REFUNDED;

        payment.setStatus(newStatus);
        paymentRepository.save(payment);

        statusUpdateService.handlePaymentStatusChange(paymentId, newStatus);

        log.info("Payment {} refunded (amount: {})", paymentId, refundAmount);
        return response;
    }

    @Transactional
    public void updatePaymentStatus(Long paymentId, PaymentStatus newStatus) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        final PaymentStatus oldStatus = payment.getStatus();
        payment.setStatus(newStatus);
        paymentRepository.save(payment);

        statusUpdateService.handlePaymentStatusChange(paymentId, newStatus);

        log.info("Payment {} status updated from {} to {}", paymentId, oldStatus, newStatus);
    }

    private void validateDonationCanAcceptPayment(Donation donation) {
        if (!donation.canAcceptNewPayment()) {
            if (donation.getStatus() == DonationStatus.COMPLETED) {
                throw new RuntimeException("Cannot create payment for completed donation");
            }
            if (donation.getStatus() == DonationStatus.FAILED) {
                throw new RuntimeException("Cannot create payment for failed donation");
            }
            if (donation.getStatus() == DonationStatus.CANCELLED) {
                throw new RuntimeException("Cannot create payment for cancelled donation");
            }
            if (donation.hasReachedMaxPaymentAttempts()) {
                throw new RuntimeException("Maximum payment attempts reached (3)");
            }
            if (donation.hasPendingPayments()) {
                throw new RuntimeException("Donation already has an active payment in progress");
            }
        }
    }

    private PaymentUiConfig buildUiConfig(PaymentProvider provider, PaymentResponse payment) {
        return switch (provider) {
            case PAYU -> PaymentUiConfig.builder()
                    .provider(PaymentProvider.PAYU)
                    .hasNativeSDK(false)
                    .sdkConfiguration(String.format("""
                        {
                            "merchantPosId": "300746",
                            "environment": "sandbox",
                            "orderId": "%s"
                        }
                        """, payment.getExternalId()))
                    .build();

            case STRIPE -> PaymentUiConfig.builder()
                    .provider(PaymentProvider.STRIPE)
                    .hasNativeSDK(false)
                    .sdkConfiguration(String.format("""
                        {
                            "publishableKey": "pk_test_...",
                            "clientSecret": "%s",
                            "appearance": {
                                "theme": "stripe"
                            }
                        }
                        """, payment.getClientSecret() != null ? payment.getClientSecret() : ""))
                    .build();
        };
    }

    private void markLowestFee(List<PaymentProviderOption> options) {
        if (options.isEmpty()) {
            return;
        }

        BigDecimal lowestFee = options.stream()
                .map(option -> option.getFees().getFeeAmount())
                .min(BigDecimal::compareTo)
                .orElse(BigDecimal.ZERO);

        log.info("Lowest fee among providers: {}", lowestFee);
    }

    public List<String> getSupportedPaymentMethods(PaymentProvider provider) {
        PaymentProviderService providerService = providerFactory.getProvider(provider);

        return Arrays.stream(PaymentMethod.values())
                .filter(providerService::supportsPaymentMethod)
                .map(Enum::name)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getPaymentProvidersHealth() {
        Map<String, Object> health = new HashMap<>();

        for (PaymentProvider provider : PaymentProvider.values()) {
            Map<String, Object> providerHealth = new HashMap<>();

            try {
                PaymentProviderService service = providerFactory.getProvider(provider);
                boolean available = service.supportsCurrency(Currency.PLN);

                providerHealth.put("status", available ? "UP" : "LIMITED");
                providerHealth.put("available", available);
                providerHealth.put("supportsPLN", available);

                List<String> supportedMethods = Arrays.stream(PaymentMethod.values())
                        .filter(service::supportsPaymentMethod)
                        .map(Enum::name)
                        .collect(Collectors.toList());
                providerHealth.put("supportedMethods", supportedMethods);

            } catch (Exception e) {
                providerHealth.put("status", "DOWN");
                providerHealth.put("available", false);
                providerHealth.put("error", e.getMessage());
            }

            health.put(provider.name().toLowerCase(), providerHealth);
        }

        return health;
    }

    public Page<PaymentResponse> getUserPaymentHistory(Pageable pageable, String status) {
        String username = getCurrentUsername();

        Page<Payment> payments;
        if (status != null && !status.isEmpty()) {
            PaymentStatus paymentStatus = PaymentStatus.valueOf(status.toUpperCase());
            payments = paymentRepository.findByDonation_DonorUsernameAndStatusOrderByCreatedAtDesc(
                    username, paymentStatus, pageable);
        } else {
            payments = paymentRepository.findByDonation_DonorUsernameOrderByCreatedAtDesc(
                    username, pageable);
        }

        return payments.map(PaymentResponse::fromEntity);
    }

    private String getCurrentUsername() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getSubject();
        }
        return authentication != null ? authentication.getName() : null;
    }

    private boolean canCancelPayment(Payment payment) {
        return payment.getStatus() == PaymentStatus.PENDING
                || payment.getStatus() == PaymentStatus.PROCESSING;
    }
}
