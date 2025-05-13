package org.petify.shelter.mapper;

import org.mapstruct.*;
import org.petify.shelter.dto.PetImageRequest;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.PetImage;

import java.util.Base64;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface PetImageMapper {

    @Mapping(target = "id", ignore = true)
    PetImage toEntity(PetImageRequest petImageRequest, @Context Pet pet);

    PetImageResponse toDto(PetImage petImage);

    default PetImage toEntityWithPet(PetImageRequest request, Pet pet) {
        PetImage petImage = toEntity(request, pet);
        petImage.setPet(pet);
        return petImage;
    }

    default byte[] map(String imageData) {
        return Base64.getDecoder().decode(imageData);
    }

    default String map(byte[] imageData) {
        return Base64.getEncoder().encodeToString(imageData);
    }
}