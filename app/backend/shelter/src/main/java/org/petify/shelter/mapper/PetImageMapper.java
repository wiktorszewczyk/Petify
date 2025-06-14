package org.petify.shelter.mapper;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.model.PetImage;
import org.petify.shelter.util.ImageUrlConverter;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE,
        componentModel = MappingConstants.ComponentModel.SPRING,
        imports = ImageUrlConverter.class)
public interface PetImageMapper {

    @Mapping(target = "imageUrl", expression = "java(ImageUrlConverter.toFullImageUrl(petImage.getImageName()))")
    PetImageResponse toDto(PetImage petImage);
}
