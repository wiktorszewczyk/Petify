package org.petify.funding.dto;

import org.petify.funding.model.PaymentMethod;

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
public class PaymentMethodOption {
    private PaymentMethod method;
    private String displayName;
    private boolean requiresAdditionalInfo;
}
