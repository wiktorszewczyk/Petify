package org.petify.funding.dto;

import org.petify.funding.model.PaymentProvider;

import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentAnalyticsResponse {
    private LocalDate date;
    private PaymentProvider provider;
    private Integer totalTransactions;
    private Integer successfulTransactions;
    private Integer failedTransactions;
    private BigDecimal totalAmount;
    private BigDecimal totalFees;
    private BigDecimal successRate;
    private BigDecimal averageTransactionAmount;
}
