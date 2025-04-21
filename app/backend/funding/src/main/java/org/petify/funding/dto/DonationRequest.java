package org.petify.funding.dto;

import lombok.*;
import org.petify.funding.model.Donation;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.MonetaryDonation;
import org.petify.funding.model.TaxDonation;

import java.math.BigDecimal;

/**
 * Payload coming from the client when creating a donation.
 */
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationRequest {
    private Long shelterId;
    private Long petId;          // optional
    private String donorUsername;
    private String donationType; // "MONEY", "TAX" or "MATERIAL"

    //for MONEY:
    private BigDecimal amount;
    private String currency;

    //for TAX:
    private Integer taxYear;
    private String krsNumber;
    private BigDecimal taxAmount;

    //for MATERIAL:
    private String itemName;
    private String itemDescription;
    private Integer quantity;
    private String unit;

    public Donation toEntity() {
        switch (donationType) {
            case "MONEY":
                return MonetaryDonation.builder()
                        .shelterId(shelterId)
                        .petId(petId)
                        .donorUsername(donorUsername)
                        .amount(amount)
                        .currency(currency)
                        .build();
            case "TAX":
                return TaxDonation.builder()
                        .shelterId(shelterId)
                        .petId(petId)
                        .donorUsername(donorUsername)
                        .taxYear(taxYear)
                        .krsNumber(krsNumber)
                        .taxAmount(taxAmount)
                        .build();
            case "MATERIAL":
                return MaterialDonation.builder()
                        .shelterId(shelterId)
                        .petId(petId)
                        .donorUsername(donorUsername)
                        .itemName(itemName)
                        .itemDescription(itemDescription)
                        .quantity(quantity)
                        .unit(unit)
                        .build();
            default:
                throw new IllegalArgumentException("Unknown donationType: " + donationType);
        }
    }
}
