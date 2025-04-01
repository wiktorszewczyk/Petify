package org.petify.shelter.dto;

import org.petify.shelter.model.Shelter;

import java.io.Serializable;

/**
 * DTO for {@link Shelter}
 */
public record ShelterRequest(
        String name
) implements Serializable {
}