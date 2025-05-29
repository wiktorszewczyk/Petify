package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.MonetaryDonation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationResponse {

    private Long id;
    private Long shelterId;
    private Long petId;
    private String donorUsername;
    private String donorEmail;
    private String donorName;
    private String message;
    private Boolean anonymous;
    private Boolean receiptRequested;
    private Instant donatedAt;
    private Instant createdAt;
    private Instant completedAt;
    private DonationType donationType;
    private DonationStatus status;

    private BigDecimal amount;
    private Currency currency;
    private BigDecimal totalFeeAmount;
    private BigDecimal netAmount;

    private String itemName;
    private BigDecimal unitPrice;
    private Integer quantity;

    public static DonationResponse fromEntity(Donation d) {
        DonationResponseBuilder builder = DonationResponse.builder()
                .id(d.getId())
                .shelterId(d.getShelterId())
                .petId(d.getPetId())
                .donorUsername(d.getDonorUsername())
                .donorEmail(d.getDonorEmail())
                .donorName(d.getDonorName())
                .message(d.getMessage())
                .anonymous(d.getAnonymous())
                .receiptRequested(d.getReceiptRequested())
                .donatedAt(d.getDonatedAt())
                .createdAt(d.getCreatedAt())
                .completedAt(d.getCompletedAt())
                .donationType(d.getDonationType())
                .status(d.getStatus())
                .amount(d.getAmount())
                .currency(d.getCurrency())
                .totalFeeAmount(d.getTotalFeeAmount())
                .netAmount(d.getNetAmount());

        if (d instanceof MaterialDonation m) {
            builder.itemName(m.getItemName())
                    .unitPrice(m.getUnitPrice())
                    .quantity(m.getQuantity());
        }

        return builder.build();
    }
}
