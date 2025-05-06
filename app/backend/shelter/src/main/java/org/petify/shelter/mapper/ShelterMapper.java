package org.petify.shelter.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.model.Shelter;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface ShelterMapper {
    ShelterResponse toDto(Shelter shelter);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "ownerUsername", ignore = true)
    @Mapping(target = "pets", ignore = true)
    Shelter toEntity(ShelterRequest request);
}
