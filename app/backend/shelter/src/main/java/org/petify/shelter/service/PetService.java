package org.petify.shelter.service;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.dto.PetResponseWithImages;
import org.petify.shelter.enums.PetType;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.petify.shelter.specification.PetSpecification;

import lombok.AllArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@AllArgsConstructor
@Service
public class PetService {
    private final PetRepository petRepository;
    private final ShelterRepository shelterRepository;
    private final FavoritePetRepository favoritePetRepository;
    private final PetMapper petMapper;

    public String getOwnerUsernameByPetId(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));
        return pet.getShelter().getOwnerUsername();
    }

    public List<PetResponse> getPets() {
        List<Pet> pets = petRepository.findAll();
        List<PetResponse> petsList = new ArrayList<>();
        for (Pet pet : pets) {
            petsList.add(petMapper.toDto(pet));
        }

        return petsList;
    }

    @Transactional(readOnly = true)
    public List<PetResponse> getFilteredPets(Boolean vaccinated, Boolean urgent, Boolean sterilized,
                                             Boolean kidFriendly, Integer minAge, Integer maxAge,
                                             PetType type, Double userLat, Double userLng, Double radiusKm,
                                             String username) {

        List<Long> favoritePetIds = favoritePetRepository.findByUsername(username)
                .stream()
                .map(fp -> fp.getPet().getId())
                .toList();

        Specification<Pet> spec = Specification.where(PetSpecification.hasVaccinated(vaccinated))
                .and(PetSpecification.isUrgent(urgent))
                .and(PetSpecification.isSterilized(sterilized))
                .and(PetSpecification.isKidFriendly(kidFriendly))
                .and(PetSpecification.ageBetween(minAge, maxAge))
                .and(PetSpecification.hasType(type))
                .and(PetSpecification.isNotArchived())
                .and(PetSpecification.hasActiveShelter())
                .and(PetSpecification.notInFavorites(favoritePetIds));

        List<Pet> filteredPets = petRepository.findAll(spec);

        Stream<Pet> stream = filteredPets.stream();

        if (userLat != null && userLng != null && radiusKm != null) {
            stream = stream.filter(p -> {
                Shelter s = p.getShelter();
                if (s == null || s.getLatitude() == null || s.getLongitude() == null) {
                    return false;
                }
                return distance(userLat, userLng, s.getLatitude(), s.getLongitude()) <= radiusKm;
            });
        }

        return stream.map(petMapper::toDto).toList();
    }

    private double distance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // promień Ziemi w km
        double lat = Math.toRadians(lat2 - lat1);
        double lon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(lat / 2) * Math.sin(lat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lon / 2) * Math.sin(lon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    public PetResponseWithImages getPetById(Long petId) {
        return petRepository.findById(petId)
                .map(petMapper::toDtoWithImages)
                .orElseThrow(() -> new PetNotFoundException(petId));
    }

    public List<Long> getAllPetIds() {
        return petRepository.findAll()
                .stream()
                .map(Pet::getId)
                .collect(Collectors.toList());
    }

    public List<PetResponse> getAllShelterPets(Long shelterId) {
        return petRepository.findByShelterId(shelterId)
                .orElse(Collections.emptyList())
                .stream()
                .map(petMapper::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public PetResponse createPet(PetRequest petRequest, Long shelterId, MultipartFile imageFile) throws IOException {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        Pet pet = petMapper.toEntityWithShelter(petRequest, shelter);
        pet.setImageName(imageFile.getOriginalFilename());
        pet.setImageType(imageFile.getContentType());
        pet.setImageData(imageFile.getBytes());

        Pet savedPet = petRepository.save(pet);

        return petMapper.toDto(savedPet);
    }

    @Transactional
    public PetImageResponse getPetImage(Long id) {
        Optional<Pet> pet = petRepository.findById(id);
        if (pet.isPresent()) {
            return new PetImageResponse(pet.get().getImageName(), pet.get().getImageType(),
                    Base64.getEncoder().encodeToString(pet.get().getImageData()));
        } else {
            throw new PetNotFoundException(id);
        }
    }

    @Transactional
    public PetResponse updatePet(PetRequest petRequest, Long petId, Long shelterId, MultipartFile imageFile) throws IOException {
        Pet existingPet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingPet.setName(petRequest.name());
        existingPet.setType(petRequest.type());
        existingPet.setBreed(petRequest.breed());
        existingPet.setAge(petRequest.age());
        existingPet.setDescription(petRequest.description());
        existingPet.setShelter(shelter);
        existingPet.setKidFriendly(petRequest.kidFriendly());
        existingPet.setSterilized(petRequest.sterilized());
        existingPet.setUrgent(petRequest.urgent());
        existingPet.setVaccinated(petRequest.vaccinated());
        existingPet.setGender(petRequest.gender());
        existingPet.setSize(petRequest.size());

        if (imageFile != null && !imageFile.isEmpty()) {
            existingPet.setImageName(imageFile.getOriginalFilename());
            existingPet.setImageType(imageFile.getContentType());
            existingPet.setImageData(imageFile.getBytes());
        }

        Pet updatedPet = petRepository.save(existingPet);

        return petMapper.toDto(updatedPet);
    }

    @Transactional
    public void deletePet(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        petRepository.delete(pet);
    }

    @Transactional
    public PetResponse archivePet(Long petId) {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        pet.setArchived(true);
        Pet savedPet = petRepository.save(pet);

        return petMapper.toDto(savedPet);
    }


    public HttpStatus validatePetForDonations(Long shelterId, Long petId) {
        try {
            Shelter shelter = shelterRepository.findById(shelterId)
                    .orElseThrow(() -> new ShelterNotFoundException(shelterId));

            if (!shelter.getIsActive()) {
                return HttpStatus.FORBIDDEN;
            }

            PetResponseWithImages pet = getPetById(petId);

            if (!pet.shelterId().equals(shelterId)) {
                return HttpStatus.NOT_FOUND;
            }

            if (pet.archived()) {
                return HttpStatus.GONE;
            }

            return HttpStatus.OK;

        } catch (ShelterNotFoundException | PetNotFoundException ex) {
            return HttpStatus.NOT_FOUND;
        }
    }
}
