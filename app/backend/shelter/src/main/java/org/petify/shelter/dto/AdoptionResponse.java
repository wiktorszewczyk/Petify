package org.petify.shelter.dto;

import org.petify.shelter.model.Adoption;

import java.io.Serializable;

/**
 * DTO for {@link Adoption}
 */
public record AdoptionResponse(
        Long id,
        Integer userId,
        Long petId,
        String adoptionStatus
) implements Serializable {}