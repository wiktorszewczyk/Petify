package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.petify.funding.model.PaymentProvider;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentProviderOption {
    private PaymentProvider provider;
    private String displayName;
    private List<PaymentMethodOption> supportedMethods;
    private PaymentFeeCalculation fees; // Używamy istniejącego!
    private boolean recommended;
}
