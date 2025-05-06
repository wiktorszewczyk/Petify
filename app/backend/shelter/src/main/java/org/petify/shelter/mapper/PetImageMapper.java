package org.petify.shelter.mapper;

import org.mapstruct.*;
import org.petify.shelter.dto.PetImageRequest;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.model.PetImage;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface PetImageMapper {
    PetImage toEntity(PetImageRequest petImageRequest);

    PetImageResponse toDto(PetImage petImage);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    PetImage partialUpdate(PetImageRequest petImageRequest, @MappingTarget PetImage petImage);
}