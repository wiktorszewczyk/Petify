package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventResponse(
        Long id,
        Long shelterId,
        Long mainImageId,
        String title,
        String shortDescription,
        String longDescription,
        Long fundraisingId,
        LocalDateTime startDate,
        LocalDateTime endDate,
        String address,
        Double latitude,
        Double longitude,
        Integer capacity,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) implements Serializable {}
