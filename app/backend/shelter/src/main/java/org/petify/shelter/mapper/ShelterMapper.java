package org.petify.shelter.mapper;

import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.model.Shelter;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

import java.util.Base64;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface ShelterMapper {
    @Mapping(target = "imageData", expression = "java(map(shelter.getImageData()))")
    ShelterResponse toDto(Shelter shelter);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "ownerUsername", ignore = true)
    @Mapping(target = "pets", ignore = true)
    @Mapping(target = "isActive", ignore = true)
    Shelter toEntity(ShelterRequest request);

    default String map(byte[] value) {
        return value != null ? Base64.getEncoder().encodeToString(value) : null;
    }
}
