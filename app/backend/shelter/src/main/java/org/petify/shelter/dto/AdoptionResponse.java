package org.petify.shelter.dto;

import org.petify.shelter.enums.AdoptionStatus;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * DTO for {@link org.petify.shelter.model.Adoption}
 */
public record AdoptionResponse(
        Long id,
        String username,
        Long petId,
        AdoptionStatus adoptionStatus,
        String motivationText,
        String fullName,
        String phoneNumber,
        String address,
        String housingType,
        boolean isHouseOwner,
        boolean hasYard,
        boolean hasOtherPets,
        String description,
        LocalDateTime applicationDate
) implements Serializable {}
