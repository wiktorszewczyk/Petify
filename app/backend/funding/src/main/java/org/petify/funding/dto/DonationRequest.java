package org.petify.funding.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import org.petify.funding.model.*;

import java.math.BigDecimal;

/**
 * Payload coming from the client when creating a donation.
 */
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationRequest {

    @NotNull
    private Long shelterId;

    private Long petId; // optional

    @NotBlank
    private String donorUsername;

    @NotNull
    private DonationType donationType;

    // MONEY
    @DecimalMin("0.01")
    private BigDecimal amount;

    @Size(min = 3, max = 3)
    private String currency;

    // TAX
    @Min(2000) @Max(2100)
    private Integer taxYear;

    private String krsNumber;

    @DecimalMin("0.01")
    private BigDecimal taxAmount;

    // MATERIAL
    private String itemName;

    private String itemDescription;

    @Min(1)
    private Integer quantity;

    private String unit;

    public Donation toEntity() {
        return switch (donationType) {
            case MONEY -> MonetaryDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorUsername(donorUsername)
                    .amount(amount)
                    .currency(currency)
                    .build();
            case TAX -> TaxDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorUsername(donorUsername)
                    .taxYear(taxYear)
                    .krsNumber(krsNumber)
                    .taxAmount(taxAmount)
                    .build();
            case MATERIAL -> MaterialDonation.builder()
                    .shelterId(shelterId)
                    .petId(petId)
                    .donorUsername(donorUsername)
                    .itemName(itemName)
                    .itemDescription(itemDescription)
                    .quantity(quantity)
                    .unit(unit)
                    .build();
        };
    }
}
