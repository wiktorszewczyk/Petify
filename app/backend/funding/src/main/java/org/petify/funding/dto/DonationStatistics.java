package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationStatistics {
    private Long shelterId;
    private Long totalDonations;
    private java.math.BigDecimal totalAmount;
    private Long completedDonations;
    private Long pendingDonations;
    private java.math.BigDecimal averageDonationAmount;
    private java.time.LocalDate lastDonationDate;
}
