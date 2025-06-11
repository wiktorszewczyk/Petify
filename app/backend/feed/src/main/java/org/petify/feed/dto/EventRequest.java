package org.petify.feed.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventRequest(
        Long mainImageId,
        @NotBlank String title,
        @NotBlank String shortDescription,
        String longDescription,
        Long fundraisingId,
        @NotNull LocalDateTime startDate,
        @NotNull LocalDateTime endDate,
        @NotBlank String address,
        Double latitude,
        Double longitude,
        Integer capacity
) implements Serializable {}
