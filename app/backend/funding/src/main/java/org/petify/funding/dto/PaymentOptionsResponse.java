package org.petify.funding.dto;

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
public class PaymentOptionsResponse {
    private Long donationId;
    private DonationResponse donation;
    private List<PaymentProviderOption> availableProviders;
    private String sessionToken;
}
