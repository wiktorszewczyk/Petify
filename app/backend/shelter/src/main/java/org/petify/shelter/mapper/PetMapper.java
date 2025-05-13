package org.petify.shelter.mapper;

import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.dto.PetResponseWithImages;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;

import org.mapstruct.BeanMapping;
import org.mapstruct.Context;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import org.mapstruct.ReportingPolicy;

import java.util.Base64;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING, uses = PetImageMapper.class)
public interface PetMapper {
    @Mapping(source = "shelter.id", target = "shelterId")
    PetResponse toDto(Pet pet);

    @Mapping(source = "shelter.id", target = "shelterId")
    @Mapping(target = "images", source = "images")
    PetResponseWithImages toDtoWithImages(Pet pet);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "adoptions", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "favoritePets", ignore = true)
    @Mapping(target = "archived", ignore = true)
    @Mapping(target = "shelter", ignore = true)
    Pet toEntity(PetRequest request, @Context Shelter shelter);

    default Pet toEntityWithShelter(PetRequest request, Shelter shelter) {
        Pet pet = toEntity(request, shelter);
        pet.setShelter(shelter);
        return pet;
    }

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "shelter", ignore = true)
    @Mapping(target = "adoptions", ignore = true)
    @Mapping(target = "imageData", ignore = true)
    @Mapping(target = "imageType", ignore = true)
    @Mapping(target = "imageName", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "favoritePets", ignore = true)
    void updatePetFromRequest(PetRequest request, @MappingTarget Pet pet);

    default byte[] map(String imageData) {
        return Base64.getDecoder().decode(imageData);
    }

    default String map(byte[] imageData) {
        return Base64.getEncoder().encodeToString(imageData);
    }
}
