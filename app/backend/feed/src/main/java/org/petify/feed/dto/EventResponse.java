package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventResponse(
        Long id,
        Long shelterId,
        String title,
        String shortDescription,
        LocalDateTime startDate,
        LocalDateTime endDate,
        String address,

        Long mainImageId,
        String longDescription,
        Long fundraisingId,
        Double latitude,
        Double longitude,
        Integer capacity,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) implements Serializable {}
