package org.petify.shelter.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.io.Serializable;

/**
 * DTO for {@link org.petify.shelter.model.PetImage}
 */
public record PetImageRequest(
        @NotBlank String imageName,
        @NotBlank String imageType,
        @NotNull String imageData
) implements Serializable {}
