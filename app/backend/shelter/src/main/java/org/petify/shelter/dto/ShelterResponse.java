package org.petify.shelter.dto;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.Shelter}
 */
public record ShelterResponse(
        Long id,
        String ownerUsername,
        String name,
        String description,
        String address,
        String phoneNumber,
        Double latitude,
        Double longitude,
        Boolean isActive,
        String imageName,
        String imageType,
        String imageData) implements Serializable {}
