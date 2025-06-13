package org.petify.image.mapper;

import org.petify.image.dto.ImageResponse;
import org.petify.image.model.Image;
import org.petify.image.util.ImageUrlConverter;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE,
        componentModel = MappingConstants.ComponentModel.SPRING,
        imports = ImageUrlConverter.class)
public interface ImageMapper {

    @Mapping(target = "imageUrl", expression = "java(ImageUrlConverter.toFullImageUrl(image.getImageName()))")
    ImageResponse toDto(Image image);
}
