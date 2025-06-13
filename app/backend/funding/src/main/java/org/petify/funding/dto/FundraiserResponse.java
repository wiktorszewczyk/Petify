package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.FundraiserStatus;
import org.petify.funding.model.FundraiserType;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundraiserResponse {
    private Long id;
    private Long shelterId;
    private String title;
    private String description;
    private BigDecimal goalAmount;
    private Currency currency;
    private FundraiserStatus status;
    private FundraiserType type;
    private Instant startDate;
    private Instant endDate;
    private Boolean isMain;
    private String needs;
    private String createdBy;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant completedAt;
    private Instant cancelledAt;

    private BigDecimal currentAmount;
    private Long donationCount;
    private Double progressPercentage;
    private Boolean canAcceptDonations;
}