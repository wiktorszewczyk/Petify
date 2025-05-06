package org.petify.shelter.mapper;

import org.mapstruct.*;
import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.model.Adoption;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface AdoptionMapper {
    Adoption toEntity(AdoptionRequest adoptionRequest);

    @Mapping(source = "pet.id", target = "petId")
    AdoptionResponse toDto(Adoption adoption);
}