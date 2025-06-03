package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.petify.funding.model.PaymentProvider;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentUiConfig {
    private PaymentProvider provider;
    private String sdkConfiguration;
    private boolean hasNativeSDK;
}
