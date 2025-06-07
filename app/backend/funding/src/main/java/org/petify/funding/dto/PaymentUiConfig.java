package org.petify.funding.dto;

import org.petify.funding.model.PaymentProvider;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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
