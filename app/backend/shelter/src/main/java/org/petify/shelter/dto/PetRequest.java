package org.petify.shelter.dto;

import org.petify.shelter.enums.Gender;
import org.petify.shelter.enums.PetSize;
import org.petify.shelter.enums.PetType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import org.hibernate.validator.constraints.Length;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.Pet}
 */
public record PetRequest(
        @NotNull(message = "Name must not be null!")
        @NotBlank(message = "Name cannot be blank!")
        @Length(message = "Name must be a string between 3 and 20 characters long!", min = 3, max = 20)
        String name,

        @NotNull(message = "You need to provide pet type!")
        PetType type,

        String breed,

        @PositiveOrZero(message = "Age of pet cannot be negative!")
        Integer age,
        @Length(message = "Description must be a string between 3 and 255 characters long!", min = 3, max = 3000)
        String description,

        @NotNull
        Gender gender,

        @NotNull
        PetSize size,

        boolean vaccinated,

        boolean urgent,

        boolean sterilized,

        boolean kidFriendly
) implements Serializable {}
