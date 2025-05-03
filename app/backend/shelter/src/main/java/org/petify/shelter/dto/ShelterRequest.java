package org.petify.shelter.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.hibernate.validator.constraints.Length;
import org.petify.shelter.model.Shelter;

import java.io.Serializable;

/**
 * DTO for {@link Shelter}
 */
public record ShelterRequest(
        @NotNull(message = "You must provide shelter name!")
        @NotEmpty(message = "Shelter name cannot be empty!")
        @NotBlank(message = "Shelter name cannot be blank!")
        @Length(message = "Shelter name has to be between 3 and 25 character long!", min = 3, max = 25)
        String name,

        @Length(message = "Description maximum size is 150 characters!", max = 150)
        String description,

        String address,

        @Pattern(regexp = "(?<!\\w)(\\(?(\\+|00)?48\\)?)?[ -]?\\d{3}[ -]?\\d{3}[ -]?\\d{3}(?!\\w)")
        String phoneNumber
) implements Serializable {}
