package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import java.math.BigDecimal;

@Entity @DiscriminatorValue("MATERIAL")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @SuperBuilder
public class MaterialDonation extends Donation {

    @Column(name = "item_name", nullable = false)
    private String itemName;

    @Column(name = "unit_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    void recalculateAmount() {
        setCurrency("PLN"); // lub pobierz z DTO
        setAmount(unitPrice.multiply(BigDecimal.valueOf(quantity)));
    }
}
