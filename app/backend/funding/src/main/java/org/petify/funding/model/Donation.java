package org.petify.funding.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
@Entity
@Table(name = "donations")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(
        name = "donation_type",
        discriminatorType = DiscriminatorType.STRING
)
public abstract class Donation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(
            mappedBy = "donation",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    private List<Payment> payments = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DonationStatus status = DonationStatus.PENDING;

    @Column(name = "shelter_id", nullable = false)
    private Long shelterId;

    @Column(name = "pet_id")
    private Long petId;

    @Column(name = "donor_username", nullable = false)
    private String donorUsername;

    @Column(name = "donated_at", nullable = false)
    private Instant donatedAt;

    @JsonProperty("donationType")
    @Column(
            name = "donation_type",
            insertable = false,
            updatable = false
    )
    @Enumerated(EnumType.STRING)
    private DonationType donationType;

    @Column(
            name = "amount",
            nullable = false,
            precision = 15,
            scale = 2
    )
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "currency", length = 3, nullable = false)
    private Currency currency = Currency.PLN;

    @Column(name = "amount_in_pln", precision = 15, scale = 2)
    private BigDecimal amountInPln;

    @Column(name = "exchange_rate", precision = 10, scale = 6)
    private BigDecimal exchangeRate;

    @Column(name = "donor_email")
    private String donorEmail;

    @Column(name = "donor_name")
    private String donorName;

    @Column(name = "message", length = 500)
    private String message;

    @Column(name = "anonymous")
    private Boolean anonymous = false;

    @Column(name = "recurring")
    private Boolean recurring = false;

    @Column(name = "recurring_frequency")
    private String recurringFrequency;

    @Column(name = "receipt_requested")
    private Boolean receiptRequested = false;

    @Column(name = "total_fee_amount", precision = 15, scale = 2)
    private BigDecimal totalFeeAmount;

    @Column(name = "net_amount", precision = 15, scale = 2)
    private BigDecimal netAmount;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Version
    private Long version;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        updatedAt = Instant.now();

        if (donatedAt == null) {
            donatedAt = Instant.now();
        }

        calculateAmountInPln();

        if (this instanceof MaterialDonation md) {
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
        calculateAmountInPln();

        if (status == DonationStatus.COMPLETED && completedAt == null) {
            completedAt = Instant.now();
        }

        if (this instanceof MaterialDonation md) {
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        }
    }

    private void calculateAmountInPln() {
        if (currency == Currency.PLN) {
            amountInPln = amount;
            exchangeRate = BigDecimal.ONE;
        } else if (exchangeRate != null) {
            amountInPln = amount.multiply(exchangeRate);
        }
    }

    @Deprecated
    public String getCurrencyAsString() {
        return currency != null ? currency.name() : Currency.PLN.name();
    }

    @Deprecated
    public void setCurrencyFromString(String currencyStr) {
        this.currency = Currency.valueOf(currencyStr);
    }
}