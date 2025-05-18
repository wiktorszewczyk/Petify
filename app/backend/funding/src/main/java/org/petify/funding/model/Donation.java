package org.petify.funding.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;
import java.time.Instant;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @SuperBuilder
@Entity
@Table(name = "donations")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "donation_type", discriminatorType = DiscriminatorType.STRING)
public abstract class Donation {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(mappedBy = "donation", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Payment payment;

    @Column(name = "shelter_id", nullable = false)
    private Long shelterId;

    @Column(name = "pet_id")
    private Long petId;

    @Column(name = "donor_username", nullable = false)
    private String donorUsername;

    @Column(name = "donated_at", nullable = false)
    private Instant donatedAt;

    @JsonProperty("donationType")
    @Enumerated(EnumType.STRING)
    @Column(name = "donation_type", insertable = false, updatable = false)
    private DonationType donationType;

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency", length = 3, nullable = false)
    private String currency;

    @PrePersist @PreUpdate
    protected void beforeSave() {
        if (donatedAt == null) {
            donatedAt = Instant.now();
        }
        if (this instanceof MaterialDonation md) {
            md.recalculateAmount();
            this.amount   = md.getAmount();
            this.currency = md.getCurrency();
        }
    }
}

