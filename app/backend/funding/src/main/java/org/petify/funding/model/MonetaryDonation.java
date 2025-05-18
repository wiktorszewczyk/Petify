package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import java.math.BigDecimal;

@Entity @DiscriminatorValue("MONEY")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @SuperBuilder
public class MonetaryDonation extends Donation {
}
