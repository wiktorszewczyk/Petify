package org.petify.reservations.dto;

import java.time.LocalDate;
import java.util.List;

public record SlotBatchRequest(
        List<Long> petIds,      // puste => allPets = true
        boolean allPets,
        LocalDate startDate,
        LocalDate endDate,
        List<TimeWindowRequest> timeWindows
) {}