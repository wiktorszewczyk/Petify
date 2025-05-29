package org.petify.funding.dto;

import org.petify.funding.model.Currency;

import lombok.Builder;
import lombok.AllArgsConstructor;
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
public class ExchangeRateResponse {
    private Currency fromCurrency;
    private Currency toCurrency;
    private BigDecimal rate;
    private Instant fetchedAt;
    private String source;
}
