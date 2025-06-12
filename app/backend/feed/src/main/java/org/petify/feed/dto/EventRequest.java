package org.petify.feed.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.hibernate.validator.constraints.Length;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventRequest(
        @NotNull(message = "Title must not be null!")
        @NotBlank(message = "Title cannot be blank!")
        @Length(message = "Title must be a string between 3 and 50 characters long!", min = 3, max = 50)
        String title,

        @NotNull(message = "Short description must not be null!")
        @NotBlank(message = "Short description cannot be blank!")
        @Length(message = "Summary must be a string between 10 and 200 characters long!", min = 10, max = 200)
        String shortDescription,

        @NotNull(message = "Start date must not be null!")
        LocalDateTime startDate,

        @NotNull(message = "End date must not be null!")
        LocalDateTime endDate,

        @NotNull(message = "Address must not be null!")
        @NotBlank(message = "Address cannot be blank!")
        String address,

        Long mainImageId,
        String longDescription,
        Long fundraisingId,
        Double latitude,
        Double longitude,
        Integer capacity
) implements Serializable {}
