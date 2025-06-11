package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundraiserStats {
    private Long fundraiserId;
    private String title;
    private BigDecimal goalAmount;
    private BigDecimal currentAmount;
    private BigDecimal remainingAmount;
    private Double progressPercentage;
    private Long totalDonations;
    private Long uniqueDonors;
    private BigDecimal averageDonation;
    private BigDecimal lastWeekAmount;
    private Boolean isGoalReached;
}