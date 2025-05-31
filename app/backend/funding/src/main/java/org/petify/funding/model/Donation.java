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

    // Dodane powiązanie z User
    @Column(name = "donor_id")
    private Integer donorId;

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

    @Column(name = "message", length = 500)
    private String message;

    @Column(name = "anonymous")
    private Boolean anonymous = false;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        updatedAt = Instant.now();

        if (donatedAt == null) {
            donatedAt = Instant.now();
        }

        if (this instanceof MaterialDonation md) {
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();

        if (status == DonationStatus.COMPLETED && completedAt == null) {
            completedAt = Instant.now();
        }

        if (this instanceof MaterialDonation md) {
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        }
    }

    public boolean isCompleted() {
        return status == DonationStatus.COMPLETED;
    }

    public boolean hasPendingPayments() {
        return payments.stream()
                .anyMatch(payment -> payment.getStatus() == PaymentStatus.PENDING ||
                        payment.getStatus() == PaymentStatus.PROCESSING);
    }

    public boolean hasSuccessfulPayment() {
        return payments.stream()
                .anyMatch(payment -> payment.getStatus() == PaymentStatus.SUCCEEDED);
    }

    public BigDecimal getTotalPaidAmount() {
        return payments.stream()
                .filter(payment -> payment.getStatus() == PaymentStatus.SUCCEEDED)
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    // Obliczanie opłat dynamicznie na podstawie Payment
    public BigDecimal getTotalFeeAmount() {
        return payments.stream()
                .filter(payment -> payment.getStatus() == PaymentStatus.SUCCEEDED)
                .map(payment -> payment.getFeeAmount() != null ? payment.getFeeAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public BigDecimal getNetAmount() {
        return getTotalPaidAmount().subtract(getTotalFeeAmount());
    }

    public boolean isDonorUsernameEmail() {
        return donorUsername != null && donorUsername.contains("@");
    }

    public boolean isDonorUsernamePhone() {
        return donorUsername != null && donorUsername.matches("^\\+?[0-9]{9,15}$");
    }
}
