package org.petify.shelter.dto;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.Shelter}
 */
public record ShelterResponse(
        Long id,
        Integer ownerId,
        String name,
        String description,
        String address,
        String phoneNumber
) implements Serializable {}