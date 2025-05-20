package org.petify.shelter.mapper;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.model.PetImage;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

import java.util.Base64;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface PetImageMapper {

    PetImageResponse toDto(PetImage petImage);

    default byte[] map(String imageData) {
        return Base64.getDecoder().decode(imageData);
    }

    default String map(byte[] imageData) {
        return Base64.getEncoder().encodeToString(imageData);
    }
}
