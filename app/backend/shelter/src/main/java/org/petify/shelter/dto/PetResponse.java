package org.petify.shelter.dto;

import org.petify.shelter.model.PetType;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.Pet}
 */
public record PetResponse(
        Long id,
        String name,
        PetType type,
        String breed,
        Integer age,
        boolean archived,
        String description,
        Long shelterId
) implements Serializable {}
