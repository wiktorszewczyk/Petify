package org.petify.shelter.dto;

import org.petify.shelter.model.Adoption;

import jakarta.validation.constraints.NotNull;

import java.io.Serializable;

/**
 * DTO for {@link Adoption}
 */
public record AdoptionRequest(@NotNull Long petId) implements Serializable {
}
