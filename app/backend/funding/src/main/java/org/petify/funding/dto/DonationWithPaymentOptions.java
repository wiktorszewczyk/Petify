package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationWithPaymentOptions {
    private DonationResponse donation;
    private List<PaymentOptionResponse> availablePaymentOptions;
    private PaymentResponse activePayment;
}
