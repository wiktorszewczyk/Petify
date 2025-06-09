package org.petify.funding.dto;

import org.petify.funding.model.PaymentProvider;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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
    private PaymentFeeCalculation fees;
    private boolean recommended;
}
