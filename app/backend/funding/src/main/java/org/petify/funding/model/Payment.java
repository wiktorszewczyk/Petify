package org.petify.funding.model;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Table(name = "payments")
public class Payment {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "donation_id", nullable = false)
    private Long donationId;

    @Column(name = "provider", nullable = false, length = 50)
    private String provider;

    @Column(name = "external_id", nullable = false, unique = true)
    private String externalId;

    @Column(name = "status", nullable = false, length = 20)
    private String status;                 // "PENDING", "SUCCEEDED", "FAILED"

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "currency", length = 3, nullable = false)
    private String currency;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}