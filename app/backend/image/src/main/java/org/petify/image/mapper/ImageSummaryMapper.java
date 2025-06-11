package org.petify.image.mapper;

import org.petify.image.dto.ImageShortResponse;
import org.petify.image.model.Image;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface ImageSummaryMapper {
    ImageShortResponse toDto(Image image);
}
