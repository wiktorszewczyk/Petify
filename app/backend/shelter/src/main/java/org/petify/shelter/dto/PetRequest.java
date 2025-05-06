package org.petify.shelter.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import org.hibernate.validator.constraints.Length;
import org.petify.shelter.enums.PetType;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.Pet}
 */
public record PetRequest(
        @NotNull(message = "Name must not be null!") @NotBlank(message = "Name cannot be blank!") @Length(message = "Name must be a string between 3 and 20 characters long!", min = 3, max = 20) String name,
        @NotNull(message = "You need to provide pet type!") PetType type,
        String breed,
        @PositiveOrZero Integer age,
        @Length(message = "Description must be a string between 3 and 50 characters long!", min = 3, max = 20) String description
) implements Serializable {}