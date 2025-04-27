package org.petify.reservations.dto;

import java.time.LocalDateTime;

public record SlotRequest(Long petId,
                          LocalDateTime startTime,
                          LocalDateTime endTime) {
}
