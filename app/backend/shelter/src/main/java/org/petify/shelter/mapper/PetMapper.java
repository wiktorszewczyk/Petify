package org.petify.shelter.mapper;

import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.dto.PetResponseWithImages;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.util.ImageUrlConverter;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE,
        componentModel = MappingConstants.ComponentModel.SPRING,
        uses = PetImageMapper.class,
        imports = ImageUrlConverter.class)
public interface PetMapper {

    @Mapping(source = "shelter.id", target = "shelterId")
    @Mapping(target = "imageUrl", expression = "java(ImageUrlConverter.toFullImageUrl(pet.getImageName()))")
    PetResponse toDto(Pet pet);

    @Mapping(source = "shelter.id", target = "shelterId")
    @Mapping(target = "images", source = "images")
    @Mapping(target = "imageUrl", expression = "java(ImageUrlConverter.toFullImageUrl(pet.getImageName()))")
    PetResponseWithImages toDtoWithImages(Pet pet);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "adoptions", ignore = true)
    @Mapping(target = "images", ignore = true)
    @Mapping(target = "favoritePets", ignore = true)
    @Mapping(target = "archived", ignore = true)
    Pet toEntity(PetRequest request);

    default Pet toEntityWithShelter(PetRequest request, Shelter shelter) {
        Pet pet = toEntity(request);
        pet.setShelter(shelter);
        return pet;
    }
}
