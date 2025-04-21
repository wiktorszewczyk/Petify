package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;

/**
 * Base class for all donations.
 */
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "donations")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "donation_type", discriminatorType = DiscriminatorType.STRING)
public abstract class Donation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "shelter_id", nullable = false)
    private Long shelterId;

    @Column(name = "donor_username", nullable = false)
    private String donorUsername;

    @Column(name = "donated_at", nullable = false)
    private Instant donatedAt;
}
