package org.petify.shelter.mapper;

import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.model.Adoption;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface AdoptionMapper {
    Adoption toEntity(AdoptionRequest adoptionRequest);

    @Mapping(source = "pet.id", target = "petId")
    AdoptionResponse toDto(Adoption adoption);
}
