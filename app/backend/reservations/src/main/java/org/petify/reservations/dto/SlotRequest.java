package org.petify.reservations.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDateTime;

public record SlotRequest(
        @NotNull(message = "Pet ID cannot be null")
        @Positive(message = "Pet ID must be positive")
        Long petId,

        @NotNull(message = "Start time cannot be null")
        @Future(message = "Start time must be in the future")
        LocalDateTime startTime,

        @NotNull(message = "End time cannot be null")
        @Future(message = "End time must be in the future")
        LocalDateTime endTime
) {}
