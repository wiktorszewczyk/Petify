package org.petify.shelter.mapper;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.model.PetImage;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.Named;
import org.mapstruct.ReportingPolicy;

import java.util.Base64;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface PetImageMapper {

    @Mapping(source = "imageData", target = "imageData", qualifiedByName = "encodeBase64")
    PetImageResponse toDto(PetImage petImage);

    @Named("encodeBase64")
    default String encodeBase64(byte[] imageData) {
        return Base64.getEncoder().encodeToString(imageData);
    }

    @Named("decodeBase64")
    default byte[] decodeBase64(String imageData) {
        return Base64.getDecoder().decode(imageData);
    }
}
