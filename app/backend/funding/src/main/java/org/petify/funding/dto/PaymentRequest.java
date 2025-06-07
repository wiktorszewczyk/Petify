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

    // Jeśli null, system wybierze najlepszego providera
    private PaymentProvider preferredProvider;

    private PaymentMethod preferredMethod;

    private String returnUrl;
    private String cancelUrl;

    // Dla BLIK payments
    private String blikCode;

    // Dla bank transfers
    private String bankCode;
}
