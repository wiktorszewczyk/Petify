package org.petify.reservations.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

import java.time.LocalDateTime;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@EqualsAndHashCode(of = {"petId", "startTime", "endTime"})
@ToString
@Entity
@Table(name = "reservation_slots",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"pet_id", "start_time", "end_time"})
        })
public class ReservationSlot {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Enumerated(EnumType.STRING)
    private ReservationStatus status;

    @Column(name = "reserved_by")
    private String reservedBy;

    public ReservationSlot(Long petId,
                           LocalDateTime startTime,
                           LocalDateTime endTime,
                           ReservationStatus status,
                           String reservedBy) {
        this.petId = petId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.status = status;
        this.reservedBy = reservedBy;
    }
}


