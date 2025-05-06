package org.petify.shelter.dto;

import jakarta.validation.constraints.NotBlank;
import org.petify.shelter.model.Adoption;

import java.io.Serializable;

/**
 * DTO for {@link Adoption}
 */
public record AdoptionRequest(
        @NotBlank String username,
        @NotBlank String motivationText,
        @NotBlank String fullName,
        @NotBlank String phoneNumber,
        @NotBlank String address,
        @NotBlank String housingType,
        boolean isHouseOwner,
        boolean hasYard,
        boolean hasOtherPets,
        String description
) implements Serializable {
}