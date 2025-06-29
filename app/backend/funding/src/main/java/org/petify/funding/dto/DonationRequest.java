package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.Fundraiser;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.MonetaryDonation;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
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

    private Long fundraiserId;

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
            case MONEY -> {
                var donation = MonetaryDonation.builder()
                        .shelterId(shelterId)
                        .petId(petId)
                        .donorUsername(donorUsername)
                        .message(message)
                        .anonymous(anonymous)
                        .amount(amount)
                        .currency(Currency.PLN)
                        .build();
                if (fundraiserId != null) {
                    donation.setFundraiser(Fundraiser.builder().id(fundraiserId).build());
                }
                yield donation;
            }

            case MATERIAL -> {
                var donation = MaterialDonation.builder()
                        .shelterId(shelterId)
                        .petId(petId)
                        .donorUsername(donorUsername)
                        .message(message)
                        .anonymous(anonymous)
                        .itemName(itemName)
                        .unitPrice(unitPrice)
                        .quantity(quantity)
                        .currency(Currency.PLN)
                        .build();
                if (fundraiserId != null) {
                    donation.setFundraiser(Fundraiser.builder().id(fundraiserId).build());
                }
                yield donation;
            }

            default -> throw new IllegalStateException("Unexpected donationType: " + donationType);
        };
    }
}
