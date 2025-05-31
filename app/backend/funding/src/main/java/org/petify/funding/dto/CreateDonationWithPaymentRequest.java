package org.petify.funding.dto;

import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateDonationWithPaymentRequest {

    @Valid
    @NotNull
    private DonationRequest donationRequest;

    private PaymentProvider preferredProvider;
    private PaymentMethod preferredMethod;
    private String returnUrl;
    private String cancelUrl;
}