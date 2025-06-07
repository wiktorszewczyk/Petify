package org.petify.funding.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.petify.funding.model.DonationType;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationIntentRequest {
    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    private Long petId;

    @NotNull(message = "Donation type is required")
    private DonationType donationType;

    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    private String message;
    private Boolean anonymous = false;

    private String itemName;
    private BigDecimal unitPrice;
    private Integer quantity;
}
