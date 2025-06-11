package org.petify.backend.dto;

import java.io.Serializable;

public record GeolocationResponse(
        String cityName,
        double latitude,
        double longitude,
        String country,
        String state,
        String displayName
) implements Serializable {}
