package org.petify.shelter.dto;

import java.io.Serializable;

public record PetImageResponse(
        String imageName,
        String imageType,
        String imageData
) implements Serializable {}
