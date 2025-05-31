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
     * Get available payment options for a donation
     */
    public List<PaymentOptionResponse> getAvailablePaymentOptions(Long donationId, String userCountry) {
        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new RuntimeException("Donation not found"));

        List<PaymentOptionResponse> options = new ArrayList<>();

        for (PaymentProvider provider : PaymentProvider.values()) {
            PaymentProviderService providerService = providerFactory.getProvider(provider);

            PaymentOptionResponse option = PaymentOptionResponse.builder()
                    .provider(provider)
                    .providerDisplayName(getProviderDisplayName(provider))
                    .supportedMethods(getSupportedMethods(provider))
                    .supportedCurrencies(getSupportedCurrencies(provider))
                    .feePercentage(getFeePercentage(provider))
                    .fixedFee(getFixedFee(provider, donation.getCurrency()))
                    .description(getProviderDescription(provider))
                    .recommended(isRecommendedProvider(provider, userCountry, donation.getCurrency()))
                    .available(isProviderAvailable(provider, donation))
                    .build();

            options.add(option);
        }

        return options.stream()
                .sorted((o1, o2) -> {
                    if (o1.isRecommended() != o2.isRecommended()) {
                        return o1.isRecommended() ? -1 : 1;
                    }
                    if (o1.isAvailable() != o2.isAvailable()) {
                        return o1.isAvailable() ? -1 : 1;
                    }
                    return 0;
                })
                .collect(Collectors.toList());
    }

    /**
     * Create a new payment
     */
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        Donation donation = donationRepository.findById(request.getDonationId())
                .orElseThrow(() -> new RuntimeException("Donation not found"));

        PaymentProvider provider = determineOptimalProvider(request, donation);
        request.setPreferredProvider(provider);

        PaymentProviderService providerService = providerFactory.getProvider(provider);
        PaymentResponse response = providerService.createPayment(request);

        if (donation.getStatus() == DonationStatus.PENDING) {
            donation.setStatus(DonationStatus.PENDING);
            donationRepository.save(donation);
        }

        log.info("Payment created successfully: {} with provider {}", response.getId(), provider);
        return response;
    }

    /**
     * Get payment by ID
     */
    public PaymentResponse getPaymentById(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return PaymentResponse.fromEntity(payment);
    }

    /**
     * Get payment by external ID
     */
    public PaymentResponse getPaymentByExternalId(String externalId) {
        Payment payment = paymentRepository.findByExternalId(externalId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return PaymentResponse.fromEntity(payment);
    }

    /**
     * Cancel a payment
     */
    @Transactional
    public PaymentResponse cancelPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        PaymentProviderService providerService = providerFactory.getProvider(payment.getProvider());
        return providerService.cancelPayment(payment.getExternalId());
    }

    /**
     * Refund a payment
     */
    @Transactional
    public PaymentResponse refundPayment(Long paymentId, BigDecimal amount) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (payment.getStatus() != PaymentStatus.SUCCEEDED) {
            throw new RuntimeException("Can only refund successful payments");
        }

        BigDecimal refundAmount = amount != null ? amount : payment.getAmount();

        PaymentProviderService providerService = providerFactory.getProvider(payment.getProvider());
        return providerService.refundPayment(payment.getExternalId(), refundAmount);
    }

    /**
     * Get user's payment history
     */
    public Page<PaymentResponse> getUserPaymentHistory(Pageable pageable, String status) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();

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
     * Get payments for a specific donation
     */
    public List<PaymentResponse> getPaymentsByDonation(Long donationId) {
        List<Payment> payments = paymentRepository.findByDonationId(donationId);
        return payments.stream()
                .map(PaymentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Handle Stripe webhook
     */
    @Transactional
    public void handleStripeWebhook(String payload, String signature) {
        PaymentProviderService stripeService = providerFactory.getProvider(PaymentProvider.STRIPE);
        stripeService.handleWebhook(payload, signature);
    }

    /**
     * Handle PayU webhook
     */
    @Transactional
    public void handlePayUWebhook(String payload, String signature) {
        PaymentProviderService payuService = providerFactory.getProvider(PaymentProvider.PAYU);
        payuService.handleWebhook(payload, signature);
    }

    /**
     * Calculate payment fee
     */
    public Map<String, Object> calculatePaymentFee(BigDecimal amount, Currency currency,
                                                   PaymentProvider provider) {
        PaymentProviderService providerService = providerFactory.getProvider(provider);
        BigDecimal fee = providerService.calculateFee(amount, currency);
        BigDecimal netAmount = amount.subtract(fee);

        Map<String, Object> result = new HashMap<>();
        result.put("amount", amount);
        result.put("currency", currency);
        result.put("provider", provider);
        result.put("fee", fee);
        result.put("netAmount", netAmount);
        result.put("feePercentage", fee.divide(amount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(new BigDecimal("100")));

        return result;
    }

    /**
     * Get supported payment methods for a provider
     */
    public List<String> getSupportedPaymentMethods(PaymentProvider provider) {
        PaymentProviderService providerService = providerFactory.getProvider(provider);

        return Arrays.stream(PaymentMethod.values())
                .filter(providerService::supportsPaymentMethod)
                .map(Enum::name)
                .collect(Collectors.toList());
    }

    /**
     * Retry a failed payment
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
                .currency(originalPayment.getCurrency())
                .amount(originalPayment.getAmount())
                .build();

        return createPayment(retryRequest);
    }

    /**
     * Get payment providers health status
     */
    public Map<String, Object> getPaymentProvidersHealth() {
        Map<String, Object> health = new HashMap<>();

        for (PaymentProvider provider : PaymentProvider.values()) {
            Map<String, Object> providerHealth = new HashMap<>();

            try {
                PaymentProviderService service = providerFactory.getProvider(provider);
                providerHealth.put("status", "UP");
                providerHealth.put("available", true);
            } catch (Exception e) {
                providerHealth.put("status", "DOWN");
                providerHealth.put("available", false);
                providerHealth.put("error", e.getMessage());
            }

            health.put(provider.name().toLowerCase(), providerHealth);
        }

        return health;
    }

    private PaymentProvider determineOptimalProvider(PaymentRequest request, Donation donation) {
        if (request.getPreferredProvider() != null) {
            return request.getPreferredProvider();
        }

        Currency currency = request.getCurrency() != null ? request.getCurrency() : donation.getCurrency();

        if (currency == Currency.PLN) {
            return PaymentProvider.PAYU;
        }

        return PaymentProvider.STRIPE;
    }

    private String getProviderDisplayName(PaymentProvider provider) {
        return switch (provider) {
            case STRIPE -> "Stripe";
            case PAYU -> "PayU";
        };
    }

    private List<PaymentMethod> getSupportedMethods(PaymentProvider provider) {
        PaymentProviderService service = providerFactory.getProvider(provider);
        return Arrays.stream(PaymentMethod.values())
                .filter(service::supportsPaymentMethod)
                .collect(Collectors.toList());
    }

    private List<Currency> getSupportedCurrencies(PaymentProvider provider) {
        PaymentProviderService service = providerFactory.getProvider(provider);
        return Arrays.stream(Currency.values())
                .filter(service::supportsCurrency)
                .collect(Collectors.toList());
    }

    private BigDecimal getFeePercentage(PaymentProvider provider) {
        return switch (provider) {
            case STRIPE -> new BigDecimal("2.9");
            case PAYU -> new BigDecimal("1.9");
        };
    }

    private BigDecimal getFixedFee(PaymentProvider provider, Currency currency) {
        if (provider == PaymentProvider.STRIPE) {
            return switch (currency) {
                case USD -> new BigDecimal("0.30");
                case EUR -> new BigDecimal("0.25");
                case GBP -> new BigDecimal("0.20");
                case PLN -> new BigDecimal("1.20");
            };
        }
        return BigDecimal.ZERO;
    }

    private String getProviderDescription(PaymentProvider provider) {
        return switch (provider) {
            case STRIPE -> "International payment processor supporting cards and digital wallets";
            case PAYU -> "Polish payment processor with BLIK and local bank transfer support";
        };
    }

    private boolean isRecommendedProvider(PaymentProvider provider, String userCountry, Currency currency) {
        if ("PL".equals(userCountry) || currency == Currency.PLN) {
            return provider == PaymentProvider.PAYU;
        }
        return provider == PaymentProvider.STRIPE;
    }

    private boolean isProviderAvailable(PaymentProvider provider, Donation donation) {
        try {
            PaymentProviderService service = providerFactory.getProvider(provider);
            return service.supportsCurrency(donation.getCurrency());
        } catch (Exception e) {
            return false;
        }
    }
}