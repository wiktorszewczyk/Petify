package org.petify.funding.model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;

@Entity
@DiscriminatorValue("MATERIAL")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class MaterialDonation extends Donation {

    @Column(name = "item_name")
    private String itemName;

    @Column(
            name = "unit_price",
            precision = 15,
            scale = 2
    )
    private BigDecimal unitPrice;

    @Column(name = "quantity")
    private Integer quantity;

    void recalculateAmount() {
        setCurrency(getCurrency() != null ? getCurrency() : Currency.PLN);
        setAmount(unitPrice.multiply(BigDecimal.valueOf(quantity)));
    }

}
