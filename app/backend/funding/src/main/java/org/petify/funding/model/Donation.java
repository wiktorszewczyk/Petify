package org.petify.funding.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorColumn;
import jakarta.persistence.DiscriminatorType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
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
    @Builder.Default
    private List<Payment> payments = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DonationStatus status = DonationStatus.PENDING;

    @Column(name = "shelter_id", nullable = false)
    private Long shelterId;

    @Column(name = "pet_id")
    private Long petId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fundraiser_id")
    private Fundraiser fundraiser;

    @Column(name = "donor_username")
    private String donorUsername;

    @Column(name = "donated_at")
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

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @Column(name = "refunded_at")
    private Instant refundedAt;

    @Column(name = "payment_attempts", nullable = false)
    @Builder.Default
    private Integer paymentAttempts = 0;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        updatedAt = Instant.now();

        if (paymentAttempts == null) {
            paymentAttempts = 0;
        }

        if (this instanceof MaterialDonation) {
            this.donationType = DonationType.MATERIAL;
            MaterialDonation md = (MaterialDonation) this;
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        } else if (this instanceof MonetaryDonation) {
            this.donationType = DonationType.MONEY;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();

        if (status == DonationStatus.COMPLETED && donatedAt == null) {
            donatedAt = Instant.now();
        }

        if (status == DonationStatus.CANCELLED && cancelledAt == null) {
            cancelledAt = Instant.now();
        }
        if (status == DonationStatus.REFUNDED && refundedAt == null) {
            refundedAt = Instant.now();
        }

        if (this instanceof MaterialDonation) {
            this.donationType = DonationType.MATERIAL;
            MaterialDonation md = (MaterialDonation) this;
            md.recalculateAmount();
            this.amount = md.getAmount();
            this.currency = md.getCurrency();
        } else if (this instanceof MonetaryDonation) {
            this.donationType = DonationType.MONEY;
        }
    }

    public boolean isCompleted() {
        return status == DonationStatus.COMPLETED;
    }

    public boolean isCancelled() {
        return status == DonationStatus.CANCELLED;
    }

    public boolean isFailed() {
        return status == DonationStatus.FAILED;
    }

    public boolean isRefunded() {
        return status == DonationStatus.REFUNDED;
    }

    public boolean hasPendingPayments() {
        if (payments == null) {
            return false;
        }
        return payments.stream()
                .anyMatch(payment -> payment.getStatus() == PaymentStatus.PENDING
                        || payment.getStatus() == PaymentStatus.PROCESSING);
    }

    public boolean hasSuccessfulPayment() {
        if (payments == null) {
            return false;
        }
        return payments.stream()
                .anyMatch(payment -> payment.getStatus() == PaymentStatus.SUCCEEDED);
    }

    public boolean canAcceptNewPayment() {
        if (status == DonationStatus.COMPLETED || status == DonationStatus.CANCELLED
                || status == DonationStatus.REFUNDED) {
            return false;
        }

        if (paymentAttempts >= 3) {
            return false;
        }

        return !hasPendingPayments();
    }

    public boolean canBeCancelled() {
        return status == DonationStatus.PENDING && !hasSuccessfulPayment();
    }

    public boolean canBeRefunded() {
        return status == DonationStatus.COMPLETED && hasSuccessfulPayment();
    }

    public void incrementPaymentAttempts() {
        this.paymentAttempts = (this.paymentAttempts == null ? 0 : this.paymentAttempts) + 1;
    }

    public boolean hasReachedMaxPaymentAttempts() {
        return this.paymentAttempts != null && this.paymentAttempts >= 3;
    }

    public BigDecimal getTotalPaidAmount() {
        if (payments == null) {
            return BigDecimal.ZERO;
        }
        return payments.stream()
                .filter(payment -> payment.getStatus() == PaymentStatus.SUCCEEDED)
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public BigDecimal getTotalFeeAmount() {
        if (payments == null) {
            return BigDecimal.ZERO;
        }
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
