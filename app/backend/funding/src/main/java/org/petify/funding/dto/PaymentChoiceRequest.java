package org.petify.funding.dto;

import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentChoiceRequest {
    @NotNull(message = "Payment provider is required")
    private PaymentProvider provider;

    private PaymentMethod method;
    private String blikCode;
    private String returnUrl;
    private String cancelUrl;
}
