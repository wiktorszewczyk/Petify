package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationWithPaymentStatusResponse {
    private DonationResponse donation;
    private PaymentResponse latestPayment;
    private Boolean isCompleted;
    private String message;
}
