package org.petify.backend.dto;

import jakarta.validation.constraints.NotBlank;

import java.io.Serializable;

public record GeolocationRequest(
        @NotBlank(message = "City name is required")
        String cityName
) implements Serializable {}
