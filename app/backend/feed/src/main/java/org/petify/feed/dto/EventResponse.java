package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventResponse(
        Long id,
        Long shelterId,
        Long mainImageId,
        String title,
        String shortDescription,
        Long fundraisingId,
        LocalDateTime startDate,
        LocalDateTime endDate,
        String address,
        Double latitude,
        Double longitude,
        Integer capacity,
        LocalDateTime createdAt
) implements Serializable {}
