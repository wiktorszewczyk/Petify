package org.petify.funding.model;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

@Entity
@DiscriminatorValue("MONEY")
@Getter
@Setter
@AllArgsConstructor
@SuperBuilder
public class MonetaryDonation extends Donation {
    // brak dodatkowych pól
}
