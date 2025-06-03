package org.petify.funding.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentChoiceRequest {
    @NotNull(message = "Payment provider is required")
    private PaymentProvider provider;

    private PaymentMethod method;
    private String blikCode;
    private String bankCode;
    private String returnUrl;
    private String cancelUrl;
}