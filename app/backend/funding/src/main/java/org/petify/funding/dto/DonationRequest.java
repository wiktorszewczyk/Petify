package org.petify.funding.dto;

import org.petify.funding.model.*;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * DTO dla tworzenia dotacji
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@DonationRequestValid
public class DonationRequest {

    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    private Long petId;

    private Integer donorId;

    private String donorUsername;

    @NotNull(message = "Donation type is required")
    private DonationType donationType;

    private String message;
    private Boolean anonymous = false;

    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    private String itemName;

    @DecimalMin(value = "0.01", message = "Unit price must be greater than 0")
    private BigDecimal unitPrice;

    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;

    public Donation toEntity() {
        return switch (donationType) {
            case MONEY -> MonetaryDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorId(donorId)
                    .donorUsername(donorUsername)
                    .message(message)
                    .anonymous(anonymous)
                    .amount(amount)
                    .currency(Currency.PLN) // Na razie tylko PLN
                    .build();

            case MATERIAL -> MaterialDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorId(donorId)
                    .donorUsername(donorUsername)
                    .message(message)
                    .anonymous(anonymous)
                    .itemName(itemName)
                    .unitPrice(unitPrice)
                    .quantity(quantity)
                    .currency(Currency.PLN) // Na razie tylko PLN
                    .build();

            default -> throw new IllegalStateException("Unexpected donationType: " + donationType);
        };
    }
}
