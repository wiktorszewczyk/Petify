package org.petify.funding.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.Map;

@Getter
@Setter
@Builder
public class PaymentInitializationResponse {
    private PaymentResponse payment;
    private PaymentUiConfig uiConfig;
    private Map<String, Object> providerSpecificData;
}
