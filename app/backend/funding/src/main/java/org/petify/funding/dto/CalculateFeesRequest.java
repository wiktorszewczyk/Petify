package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CalculateFeesRequest {
    @jakarta.validation.constraints.NotNull(message = "Amount is required")
    @jakarta.validation.constraints.DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private java.math.BigDecimal amount;

    private org.petify.funding.model.PaymentProvider provider;
}
