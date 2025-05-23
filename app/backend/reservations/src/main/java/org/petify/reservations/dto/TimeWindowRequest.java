package org.petify.reservations.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalTime;

public record TimeWindowRequest(
        @NotNull(message = "Start time cannot be null")
        LocalTime start,

        @NotNull(message = "End time cannot be null")
        LocalTime end
) {}