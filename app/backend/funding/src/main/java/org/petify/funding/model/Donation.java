package org.petify.funding.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import java.time.Instant;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
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

    @Column(name = "pet_id", nullable = true)
    private Long petId;

    @Column(name = "donor_username", nullable = false)
    private String donorUsername;

    @Column(name = "donated_at", nullable = false)
    private Instant donatedAt;

    /**
     * Read-only view of the discriminator column.
     */
    @JsonProperty("donationType")
    @Enumerated(EnumType.STRING)
    @Column(name = "donation_type", insertable = false, updatable = false)
    private DonationType donationType;

    @PrePersist
    protected void onCreate() {
        if (donatedAt == null) {
            donatedAt = Instant.now();
        }
    }
}
