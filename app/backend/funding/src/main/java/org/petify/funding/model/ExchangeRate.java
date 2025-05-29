package org.petify.funding.model;

import jakarta.persistence.Column;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "exchange_rates")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeRate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_currency", nullable = false)
    private Currency fromCurrency;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_currency", nullable = false)
    private Currency toCurrency;

    @Column(name = "rate", nullable = false, precision = 10, scale = 6)
    private BigDecimal rate;

    @Column(name = "fetched_at", nullable = false)
    private Instant fetchedAt;

    @Column(name = "source")
    private String source;
}