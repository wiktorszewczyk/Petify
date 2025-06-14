package org.petify.shelter.dto;

import org.petify.shelter.enums.Gender;
import org.petify.shelter.enums.PetSize;
import org.petify.shelter.enums.PetType;

import java.io.Serializable;
import java.util.List;

/**
 * DTO for {@link org.petify.shelter.model.Pet}
 */
public record PetResponseWithImages(
        Long id,
        String name,
        PetType type,
        String breed,
        Integer age,
        boolean archived,
        String description,
        Long shelterId,
        Gender gender,
        PetSize size,
        boolean vaccinated,
        boolean urgent,
        boolean sterilized,
        boolean kidFriendly,
        String imageUrl,
        List<PetImageResponse> images) implements Serializable {}
