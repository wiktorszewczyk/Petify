package org.petify.funding.model;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.MapKeyColumn;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

@Entity
@Table(name = "payments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "donation_id", nullable = false)
    private Donation donation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentStatus status = PaymentStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PaymentProvider provider;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 20)
    private PaymentMethod paymentMethod;

    @Column(name = "external_id", nullable = false, unique = true)
    private String externalId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(length = 3, nullable = false)
    private Currency currency;

    @Column(name = "exchange_rate", precision = 10, scale = 6)
    private BigDecimal exchangeRate;

    @Column(name = "amount_in_pln", precision = 15, scale = 2)
    private BigDecimal amountInPln;

    @Column(name = "fee_amount", precision = 15, scale = 2)
    private BigDecimal feeAmount;

    @Column(name = "net_amount", precision = 15, scale = 2)
    private BigDecimal netAmount;

    @Column(name = "failure_reason")
    private String failureReason;

    @Column(name = "failure_code")
    private String failureCode;

    @ElementCollection
    @CollectionTable(name = "payment_metadata",
            joinColumns = @JoinColumn(name = "payment_id"))
    @MapKeyColumn(name = "metadata_key")
    @Column(name = "metadata_value")
    private Map<String, String> metadata;

    @Column(name = "client_secret")
    private String clientSecret;

    @Column(name = "checkout_url")
    private String checkoutUrl;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @PrePersist
    protected void onCreate() {
        createdAt = Instant.now();
        updatedAt = Instant.now();
        calculateAmounts();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
        calculateAmounts();
    }

    private void calculateAmounts() {
        if (amount != null && currency != null) {
            if (currency == Currency.PLN) {
                amountInPln = amount;
                exchangeRate = BigDecimal.ONE;
            } else if (exchangeRate != null) {
                amountInPln = amount.multiply(exchangeRate);
            }

            // Calculate fees (example: 2.9% + 0.30 PLN for Stripe, 1.9% for PayU)
            if (provider == PaymentProvider.STRIPE) {
                feeAmount = amountInPln.multiply(new BigDecimal("0.029"))
                        .add(new BigDecimal("0.30"));
            } else if (provider == PaymentProvider.PAYU) {
                feeAmount = amountInPln.multiply(new BigDecimal("0.019"));
            }

            if (feeAmount != null) {
                netAmount = amountInPln.subtract(feeAmount);
            }
        }
    }
}
