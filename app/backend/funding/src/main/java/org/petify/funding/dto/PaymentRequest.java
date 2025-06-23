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
@lombok.Builder
public class PaymentRequest {

    @NotNull(message = "Donation ID is required")
    private Long donationId;

    private PaymentProvider preferredProvider;

    private PaymentMethod preferredMethod;

    private String returnUrl;
    private String cancelUrl;

    private String blikCode;

    private String bankCode;
}
