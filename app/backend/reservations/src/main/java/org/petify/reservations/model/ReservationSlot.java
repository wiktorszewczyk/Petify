package org.petify.reservations.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
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


