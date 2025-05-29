package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.model.PaymentStatus;

import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentResponse {

    private Long id;
    private Long donationId;
    private PaymentStatus status;
    private PaymentProvider provider;
    private PaymentMethod paymentMethod;
    private String externalId;
    private BigDecimal amount;
    private Currency currency;
    private BigDecimal feeAmount;
    private BigDecimal netAmount;
    private String failureReason;
    private String failureCode;
    private String clientSecret;
    private String checkoutUrl;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant expiresAt;
    private Map<String, String> metadata;

    public static PaymentResponse fromEntity(org.petify.funding.model.Payment payment) {
        return PaymentResponse.builder()
                .id(payment.getId())
                .donationId(payment.getDonation().getId())
                .status(payment.getStatus())
                .provider(payment.getProvider())
                .paymentMethod(payment.getPaymentMethod())
                .externalId(payment.getExternalId())
                .amount(payment.getAmount())
                .currency(payment.getCurrency())
                .feeAmount(payment.getFeeAmount())
                .netAmount(payment.getNetAmount())
                .failureReason(payment.getFailureReason())
                .failureCode(payment.getFailureCode())
                .clientSecret(payment.getClientSecret())
                .checkoutUrl(payment.getCheckoutUrl())
                .createdAt(payment.getCreatedAt())
                .updatedAt(payment.getUpdatedAt())
                .expiresAt(payment.getExpiresAt())
                .metadata(payment.getMetadata())
                .build();
    }
}
