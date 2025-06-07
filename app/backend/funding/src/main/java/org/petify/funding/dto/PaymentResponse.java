package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.model.PaymentStatus;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@lombok.Builder
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
    private java.time.Instant createdAt;
    private java.time.Instant updatedAt;
    private java.time.Instant expiresAt;

    public static PaymentResponse fromEntity(Payment payment) {
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
                .build();
    }
}
