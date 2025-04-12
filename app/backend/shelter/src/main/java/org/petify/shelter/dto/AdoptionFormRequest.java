package org.petify.shelter.dto;

import jakarta.validation.constraints.NotNull;
import org.petify.shelter.model.AdoptionForm;

import java.io.Serializable;

/**
 * DTO for {@link AdoptionForm}
 */
public record AdoptionFormRequest(@NotNull Long petId) implements Serializable {
}