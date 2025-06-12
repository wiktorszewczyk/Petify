package org.petify.shelter.dto;

import java.io.Serializable;

public record PetImageResponse(
        String imageUrl
) implements Serializable {}
