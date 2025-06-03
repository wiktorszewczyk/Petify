package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.petify.funding.model.PaymentMethod;

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
