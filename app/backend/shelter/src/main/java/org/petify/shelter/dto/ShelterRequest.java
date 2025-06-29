package org.petify.shelter.dto;

import org.petify.shelter.model.Shelter;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import org.hibernate.validator.constraints.Length;
import org.hibernate.validator.constraints.Range;

import java.io.Serializable;

/**
 * DTO for {@link Shelter}
 */
public record ShelterRequest(
        @NotNull(message = "Shelter name cannot be null!")
        @NotBlank(message = "Shelter name cannot be blank!")
        @Length(message = "Shelter name has to be between 3 and 255 characters long!", min = 3, max = 255)
        String name,

        @NotNull(message = "Shelter description cannot be null!")
        @NotBlank(message = "Shelter description cannot be blank!")
        String description,

        @NotNull(message = "Shelter address cannot be null!")
        String address,

        @NotNull @Pattern(regexp = "(?<!\\w)(\\(?(\\+|00)?48\\)?)?[ -]?\\d{3}[ -]?\\d{3}[ -]?\\d{3}(?!\\w)")
        String phoneNumber,

        @NotNull @Range(min = -90, max = 90, message = "Latitude has to be between -90 and 90 degrees!")
        Double latitude,

        @NotNull @Range(min = -180, max = 180, message = "Longitude has to be between -180 and 180 degrees!")
        Double longitude
) implements Serializable {}
