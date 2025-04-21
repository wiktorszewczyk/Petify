package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

/**
 * Material donation - for example, food, toys, etc.
 */
@Entity
@DiscriminatorValue("MATERIAL")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class MaterialDonation extends Donation {

    @Column(name = "item_name", nullable = false)
    private String itemName;

    @Column(name = "item_description")
    private String itemDescription;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    /**
     * Unit of measurement for the quantity (e.g., kg, liters, pieces).
     */
    @Column(name = "unit", length = 10, nullable = false)
    private String unit;
}
