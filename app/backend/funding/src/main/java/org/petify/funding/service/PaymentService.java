package org.petify.funding.service;

import org.petify.funding.dto.*;
import org.petify.funding.model.*;
import org.petify.funding.model.Currency;
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
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final DonationRepository donationRepository;
    private final PaymentProviderFactory providerFactory;

    /**
     * Tworzy nową płatność dla dotacji
     */
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        log.info("Creating payment for donation {}", request.getDonationId());

        Donation donation = donationRepository.findById(request.getDonationId())
                .orElseThrow(() -> new RuntimeException("Donation not found"));

        validateDonationCanAcceptPayment(donation);

        PaymentProvider provider = determineOptimalProvider(request, donation);

        PaymentProviderService providerService = providerFactory.getProvider(provider);

        PaymentRequest fullRequest = buildFullPaymentRequest(request, donation, provider);

        PaymentResponse response = providerService.createPayment(fullRequest);

        updateDonationAfterPaymentCreation(donation);

        log.info("Payment created successfully: {} with provider {}", response.getId(), provider);
        return response;
    }

    /**
     * Pobiera status płatności
     */
    public PaymentResponse getPaymentById(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return PaymentResponse.fromEntity(payment);
    }

    /**
     * Pobiera płatność po external ID
     */
    public PaymentResponse getPaymentByExternalId(String externalId) {
        Payment payment = paymentRepository.findByExternalId(externalId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return PaymentResponse.fromEntity(payment);
    }

    /**
     * Anuluje płatność
     */
    @Transactional
    public PaymentResponse cancelPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (!canCancelPayment(payment)) {
            throw new RuntimeException("Payment cannot be cancelled in current state: " + payment.getStatus());
        }

        PaymentProviderService providerService = providerFactory.getProvider(payment.getProvider());
        return providerService.cancelPayment(payment.getExternalId());
    }

    /**
     * Zwraca płatność (tylko dla adminów)
     */
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
        return providerService.refundPayment(payment.getExternalId(), refundAmount);
    }

    /**
     * Historia płatności użytkownika
     */
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

    /**
     * Pobiera wszystkie płatności dla konkretnej dotacji
     */
    public List<PaymentResponse> getPaymentsByDonation(Long donationId) {
        List<Payment> payments = paymentRepository.findByDonationId(donationId);
        return payments.stream()
                .map(PaymentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Oblicza opłatę za płatność
     */
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
                .feePercentage(fee.divide(amount, 4, java.math.RoundingMode.HALF_UP)
                        .multiply(new BigDecimal("100")))
                .build();
    }

    /**
     * Sprawdza dostępność providerów płatności
     */
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

    /**
     * Obsługa webhook'ów
     */
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

    /**
     * Ponawia nieudaną płatność
     */
    @Transactional
    public PaymentResponse retryPayment(Long paymentId) {
        Payment originalPayment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (originalPayment.getStatus() != PaymentStatus.FAILED) {
            throw new RuntimeException("Can only retry failed payments");
        }

        PaymentRequest retryRequest = PaymentRequest.builder()
                .donationId(originalPayment.getDonation().getId())
                .preferredProvider(originalPayment.getProvider())
                .preferredMethod(originalPayment.getPaymentMethod())
                .build();

        return createPayment(retryRequest);
    }

    private void validateDonationCanAcceptPayment(Donation donation) {
        if (donation.getStatus() == DonationStatus.COMPLETED) {
            throw new RuntimeException("Cannot create payment for completed donation");
        }

        if (donation.getStatus() == DonationStatus.FAILED) {
            throw new RuntimeException("Cannot create payment for failed donation");
        }

        boolean hasActivePendingPayment = donation.getPayments().stream()
                .anyMatch(p -> p.getStatus() == PaymentStatus.PENDING ||
                        p.getStatus() == PaymentStatus.PROCESSING);

        if (hasActivePendingPayment) {
            throw new RuntimeException("Donation already has an active payment in progress");
        }
    }

    private PaymentProvider determineOptimalProvider(PaymentRequest request, Donation donation) {
        if (request.getPreferredProvider() != null) {
            return request.getPreferredProvider();
        }

        return PaymentProvider.PAYU;
    }

    private PaymentRequest buildFullPaymentRequest(PaymentRequest request, Donation donation, PaymentProvider provider) {
        return PaymentRequest.builder()
                .donationId(request.getDonationId())
                .preferredProvider(provider)
                .preferredMethod(request.getPreferredMethod())
                .returnUrl(request.getReturnUrl())
                .cancelUrl(request.getCancelUrl())
                .blikCode(request.getBlikCode())
                .bankCode(request.getBankCode())
                .build();
    }

    private void updateDonationAfterPaymentCreation(Donation donation) {
        donationRepository.save(donation);
    }

    private boolean canCancelPayment(Payment payment) {
        return payment.getStatus() == PaymentStatus.PENDING ||
                payment.getStatus() == PaymentStatus.PROCESSING;
    }

    private String getCurrentUsername() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getSubject();
        }
        return authentication != null ? authentication.getName() : null;
    }

    /**
     * DTO dla obliczenia opłat
     */
    @lombok.Getter
    @lombok.Setter
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    @lombok.Builder
    public static class PaymentFeeCalculation {
        private BigDecimal grossAmount;
        private BigDecimal feeAmount;
        private BigDecimal netAmount;
        private BigDecimal feePercentage;
        private PaymentProvider provider;
        private Currency currency;
    }
}
