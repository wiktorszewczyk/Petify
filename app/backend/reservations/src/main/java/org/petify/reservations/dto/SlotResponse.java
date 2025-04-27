package org.petify.reservations.dto;

import org.petify.reservations.model.ReservationStatus;

import java.time.LocalDateTime;

public record SlotResponse(Long id, Long petId,
                           LocalDateTime startTime,
                           LocalDateTime endTime,
                           ReservationStatus status,
                           String reservedBy) {}