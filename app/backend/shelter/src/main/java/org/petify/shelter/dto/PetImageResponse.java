package org.petify.shelter.dto;

import java.io.Serializable;

public record PetImageResponse(
        String imageName,
        String imageType,
        byte[] imageData
) implements Serializable {}
