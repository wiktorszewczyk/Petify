package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.MaterialDonation;
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
public class DonationResponse {

    private Long id;
    private Long shelterId;
    private Long petId;
    private Integer donorId;
    private String donorUsername;
    private String message;
    private Boolean anonymous;
    private java.time.Instant donatedAt;
    private java.time.Instant createdAt;
    private java.time.Instant completedAt;
    private java.time.Instant cancelledAt;
    private java.time.Instant refundedAt;
    private DonationType donationType;
    private DonationStatus status;

    private BigDecimal amount;
    private Currency currency;

    private BigDecimal totalFeeAmount;
    private BigDecimal netAmount;

    private String itemName;
    private BigDecimal unitPrice;
    private Integer quantity;

    private Integer paymentAttempts;
    private Boolean canAcceptNewPayment;
    private Boolean canBeCancelled;
    private Boolean canBeRefunded;

    private java.util.List<PaymentSummary> payments;

    public static DonationResponse fromEntity(Donation d) {
        DonationResponseBuilder builder = DonationResponse.builder()
                .id(d.getId())
                .shelterId(d.getShelterId())
                .petId(d.getPetId())
                .donorId(d.getDonorId())
                .donorUsername(d.getDonorUsername())
                .message(d.getMessage())
                .anonymous(d.getAnonymous())
                .donatedAt(d.getDonatedAt())
                .createdAt(d.getCreatedAt())
                .completedAt(d.getCompletedAt())
                .cancelledAt(d.getCancelledAt())
                .refundedAt(d.getRefundedAt())
                .donationType(d.getDonationType())
                .status(d.getStatus())
                .amount(d.getAmount())
                .currency(d.getCurrency())
                .totalFeeAmount(d.getTotalFeeAmount())
                .netAmount(d.getNetAmount())
                .paymentAttempts(d.getPaymentAttempts())
                .canAcceptNewPayment(d.canAcceptNewPayment())
                .canBeCancelled(d.canBeCancelled())
                .canBeRefunded(d.canBeRefunded());

        if (d instanceof MaterialDonation m) {
            builder.itemName(m.getItemName())
                    .unitPrice(m.getUnitPrice())
                    .quantity(m.getQuantity());
        }

        if (d.getPayments() != null && !d.getPayments().isEmpty()) {
            java.util.List<PaymentSummary> paymentSummaries = d.getPayments().stream()
                    .map(PaymentSummary::fromEntity)
                    .collect(java.util.stream.Collectors.toList());
            builder.payments(paymentSummaries);
        } else {
            builder.payments(new java.util.ArrayList<>());
        }

        return builder.build();
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @lombok.Builder
    public static class PaymentSummary {
        private Long id;
        private PaymentStatus status;
        private PaymentProvider provider;
        private PaymentMethod paymentMethod;
        private BigDecimal amount;
        private BigDecimal feeAmount;
        private java.time.Instant createdAt;
        private java.time.Instant updatedAt;
        private String failureReason;
        private String failureCode;

        public static PaymentSummary fromEntity(Payment payment) {
            return PaymentSummary.builder()
                    .id(payment.getId())
                    .status(payment.getStatus())
                    .provider(payment.getProvider())
                    .paymentMethod(payment.getPaymentMethod())
                    .amount(payment.getAmount())
                    .feeAmount(payment.getFeeAmount())
                    .createdAt(payment.getCreatedAt())
                    .updatedAt(payment.getUpdatedAt())
                    .failureReason(payment.getFailureReason())
                    .failureCode(payment.getFailureCode())
                    .build();
        }
    }
}
