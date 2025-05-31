package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.petify.funding.service.PaymentService;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationWithPaymentResponse {
    private DonationResponse donation;
    private PaymentResponse payment;
    private PaymentService.PaymentFeeCalculation feeInformation;
}