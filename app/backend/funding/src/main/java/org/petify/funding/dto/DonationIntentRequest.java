package org.petify.funding.dto;

import org.petify.funding.model.DonationType;

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
@DonationIntentRequestValid
public class DonationIntentRequest {
    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    private Long petId;

    private Long fundraiserId;

    @NotNull(message = "Donation type is required")
    private DonationType donationType;

    private BigDecimal amount;

    private String message;
    private Boolean anonymous = false;

    private String itemName;
    private BigDecimal unitPrice;
    private Integer quantity;
}
