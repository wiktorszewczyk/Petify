package org.petify.shelter.dto;

import org.petify.shelter.model.AdoptionStatus;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.AdoptionForm}
 */
public record AdoptionFormResponse(
        Long id,
        Integer userId,
        Long petId,
        String adoptionStatus
) implements Serializable {}