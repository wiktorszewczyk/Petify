package org.petify.reservations.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;
import java.util.List;

public record SlotBatchRequest(
        List<@NotNull @Positive Long> petIds, //empty = all pets

        boolean allPets,

        @NotNull(message = "Start date cannot be null")
        @FutureOrPresent(message = "Start date must be today or in the future")
        LocalDate startDate,

        @NotNull(message = "End date cannot be null")
        @FutureOrPresent(message = "End date must be today or in the future")
        LocalDate endDate,

        @NotEmpty(message = "Time windows cannot be empty")
        @Valid
        List<TimeWindowRequest> timeWindows
) {}
