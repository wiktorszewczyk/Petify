package org.petify.funding.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import org.petify.funding.model.*;
import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@DonationRequestValid
public class DonationRequest {

    @NotNull
    private Long shelterId;

    private Long petId;

    @NotBlank
    private String donorUsername;

    @NotNull
    private DonationType donationType;

    // monetary
    @DecimalMin("0.01")
    private BigDecimal amount;

    @Pattern(regexp = "[A-Z]{3}")
    private String currency;

    // material
    @NotBlank
    private String itemName;

    @DecimalMin("0.01")
    private BigDecimal unitPrice;

    @Min(1)
    private Integer quantity;

    public Donation toEntity() {
        return switch (donationType) {
            case MONEY ->
                    MonetaryDonation.builder()
                            .shelterId(shelterId)
                            .donorUsername(donorUsername)
                            .amount(amount)
                            .currency(currency)
                            .build();
            case MATERIAL ->
                    MaterialDonation.builder()
                            .shelterId(shelterId)
                            .petId(petId)
                            .donorUsername(donorUsername)
                            .itemName(itemName)
                            .unitPrice(unitPrice)
                            .quantity(quantity)
                            .currency(currency)
                            .build();
        };
    }
}
