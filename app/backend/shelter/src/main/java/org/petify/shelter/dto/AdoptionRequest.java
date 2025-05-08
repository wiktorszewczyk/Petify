package org.petify.shelter.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.petify.shelter.model.Adoption;

import java.io.Serializable;

/**
 * DTO for {@link Adoption}
 */
public record AdoptionRequest(
        @NotBlank String motivationText,
        @NotBlank String fullName,
        @NotBlank String phoneNumber,
        @NotBlank String address,
        @NotBlank String housingType,
        @NotNull boolean isHouseOwner,
        @NotNull boolean hasYard,
        @NotNull boolean hasOtherPets,
        String description
) implements Serializable {
}