package org.petify.backend.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record UserLocationResponse(
        String city,
        Double latitude,
        Double longitude,
        Double preferredSearchDistanceKm,
        Boolean autoLocationEnabled,
        LocalDateTime locationUpdatedAt,
        boolean hasLocation,
        boolean hasCompleteLocationProfile
) implements Serializable {}
