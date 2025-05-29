package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentOptionResponse {

    private PaymentProvider provider;
    private String providerDisplayName;
    private List<PaymentMethod> supportedMethods;
    private List<Currency> supportedCurrencies;
    private BigDecimal feePercentage;
    private BigDecimal fixedFee;
    private String description;
    private boolean recommended;
    private boolean available;
    private String unavailableReason;
}
