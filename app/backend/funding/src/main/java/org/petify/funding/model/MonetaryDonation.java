package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Financial donation.
 */
@Entity
@DiscriminatorValue("MONEY")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class MonetaryDonation extends Donation {

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    /**
     * Currency code in ISO 4217 format.
     */
    @Column(name = "currency", length = 3, nullable = false)
    private String currency;
}