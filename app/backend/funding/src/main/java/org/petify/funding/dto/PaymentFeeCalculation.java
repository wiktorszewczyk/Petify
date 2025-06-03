package org.petify.funding.dto;

import lombok.*;
import org.petify.funding.model.Currency;
import org.petify.funding.model.PaymentProvider;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentFeeCalculation {
    private BigDecimal grossAmount;
    private BigDecimal feeAmount;
    private BigDecimal netAmount;
    private BigDecimal feePercentage;
    private PaymentProvider provider;
    private Currency currency;
}
