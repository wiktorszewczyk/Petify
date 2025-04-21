package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;

/**
 * Tax donation - 1% of income tax.
 */
@Entity
@DiscriminatorValue("TAX")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class TaxDonation extends Donation {

    @Column(name = "tax_year", nullable = false)
    private Integer taxYear;

    @Column(name = "krs_number", length = 20, nullable = false)
    private String krsNumber;

    @Column(name = "tax_amount", precision = 15, scale = 2)
    private BigDecimal taxAmount;
}