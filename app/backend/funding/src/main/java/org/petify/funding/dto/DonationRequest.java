package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.MonetaryDonation;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@DonationRequestValid
public class DonationRequest {

    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    private Long petId;

    @NotBlank(message = "Donor username is required")
    private String donorUsername;

    @NotNull(message = "Donation type is required")
    private DonationType donationType;

    private String message;
    private Boolean anonymous = false;
    private Boolean receiptRequested = false;

    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    @NotNull(message = "Currency is required")
    private Currency currency = Currency.PLN;

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
                    .donorUsername(donorUsername)
                    .message(message)
                    .anonymous(anonymous)
                    .receiptRequested(receiptRequested)
                    .amount(amount)
                    .currency(currency)
                    .build();

            case MATERIAL -> MaterialDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorUsername(donorUsername)
                    .message(message)
                    .anonymous(anonymous)
                    .receiptRequested(receiptRequested)
                    .itemName(itemName)
                    .unitPrice(unitPrice)
                    .quantity(quantity)
                    .currency(currency)
                    .build();

            default -> throw new IllegalStateException("Unexpected donationType: " + donationType);
        };
    }
}
