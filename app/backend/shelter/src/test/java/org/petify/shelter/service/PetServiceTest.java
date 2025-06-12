package org.petify.shelter.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.shelter.dto.*;
import org.petify.shelter.enums.*;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.PetMapper;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.FavoritePetRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PetServiceTest {

    @Mock
    private PetRepository petRepository;

    @Mock
    private ShelterRepository shelterRepository;

    @Mock
    private FavoritePetRepository favoritePetRepository;

    @Mock
    private PetMapper petMapper;

    @Mock
    private MultipartFile multipartFile;

    @InjectMocks
    private PetService petService;

    @BeforeEach
    void setUp() {
        petRepository.deleteAll();
        shelterRepository.deleteAll();

        Shelter shelter = new Shelter();
        shelter.setName("Test Shelter");

        Pet pet1 = new Pet();
        pet1.setName("Pet1");
        pet1.setType(PetType.DOG);
        pet1.setShelter(shelter);

        Pet pet2 = new Pet();
        pet2.setName("Pet2");
        pet2.setType(PetType.CAT);
        pet2.setShelter(shelter);
    }

    @Test
    void getOwnerUsernameByPetId_WhenPetExists_ShouldReturnUsername() {
        // Arrange
        Long petId = 1L;
        String expectedUsername = "owner1";
        Pet pet = new Pet();
        Shelter shelter = new Shelter();
        shelter.setOwnerUsername(expectedUsername);
        pet.setShelter(shelter);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act
        String result = petService.getOwnerUsernameByPetId(petId);

        // Assert
        assertThat(result).isEqualTo(expectedUsername);
    }

    @Test
    void getOwnerUsernameByPetId_WhenPetNotExists_ShouldThrowException() {
        // Arrange
        Long petId = 1L;
        when(petRepository.findById(petId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> petService.getOwnerUsernameByPetId(petId))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void getFilteredPets_WhenNoPetsMatchCriteria_ShouldReturnEmptyList() {
        // Arrange
        when(favoritePetRepository.findByUsername(anyString())).thenReturn(Collections.emptyList());
        when(petRepository.findAll(any(Specification.class))).thenReturn(Collections.emptyList());

        // Act
        List<PetResponse> result = petService.getFilteredPets(
                true, false, true, true,
                1, 5, PetType.DOG, 50.0, 20.0, 10.0, "user1");

        // Assert
        assertThat(result).isEmpty();
    }

    @Test
    void getPets_ShouldReturnListOfPetResponses() {
        // Arrange
        Shelter shelter = new Shelter();
        shelter.setId(1L);

        Pet pet1 = new Pet();
        pet1.setId(1L);
        pet1.setName("Pet1");
        pet1.setType(PetType.DOG);
        pet1.setShelter(shelter);

        Pet pet2 = new Pet();
        pet2.setId(2L);
        pet2.setName("Pet2");
        pet2.setType(PetType.CAT);
        pet2.setShelter(shelter);

        List<Pet> pets = List.of(pet1, pet2);

        PetResponse petResponse1 = createPetResponse(1L, "Pet1", PetType.DOG);
        PetResponse petResponse2 = createPetResponse(2L, "Pet2", PetType.CAT);

        when(petRepository.findAll()).thenReturn(pets);
        when(petMapper.toDto(pet1)).thenReturn(petResponse1);
        when(petMapper.toDto(pet2)).thenReturn(petResponse2);

        // Act
        List<PetResponse> result = petService.getPets();

        // Assert
        assertThat(result)
                .hasSize(2)
                .containsExactly(petResponse1, petResponse2);
    }

    @Test
    void getAllShelterPets_ShouldReturnPetsForShelter() {
        // Arrange
        Long shelterId = 1L;
        Shelter shelter = new Shelter();
        shelter.setId(shelterId);

        Pet pet1 = new Pet();
        pet1.setId(1L);
        pet1.setName("Pet1");
        pet1.setType(PetType.DOG);
        pet1.setShelter(shelter);

        Pet pet2 = new Pet();
        pet2.setId(2L);
        pet2.setName("Pet2");
        pet2.setType(PetType.CAT);
        pet2.setShelter(shelter);

        List<Pet> pets = List.of(pet1, pet2);

        PetResponse petResponse1 = createPetResponse(1L, "Pet1", PetType.DOG);
        PetResponse petResponse2 = createPetResponse(2L, "Pet2", PetType.CAT);

        when(petRepository.findByShelterId(shelterId)).thenReturn(Optional.of(pets));
        when(petMapper.toDto(pet1)).thenReturn(petResponse1);
        when(petMapper.toDto(pet2)).thenReturn(petResponse2);

        // Act
        List<PetResponse> result = petService.getAllShelterPets(shelterId);

        // Assert
        assertThat(result)
                .hasSize(2)
                .containsExactly(petResponse1, petResponse2);
    }

    @Test
    void getPetById_WhenPetExists_ShouldReturnPetResponseWithImages() {
        // Arrange
        Long petId = 1L;
        Pet pet = new Pet();
        PetResponseWithImages expectedResponse = new PetResponseWithImages(
                1L, "Pet1", PetType.DOG, "Breed1", 2, false, "Desc1",
                1L, Gender.MALE, PetSize.MEDIUM, true, false, true, true,
                null, null, null, Collections.emptyList());

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(petMapper.toDtoWithImages(pet)).thenReturn(expectedResponse);

        // Act
        PetResponseWithImages result = petService.getPetById(petId);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);
    }

    @Test
    void getPetById_WhenPetNotExists_ShouldThrowException() {
        // Arrange
        Long petId = 1L;
        when(petRepository.findById(petId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> petService.getPetById(petId))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void getAllPetIds_ShouldReturnListOfIds() {
        // Arrange
        Pet pet1 = new Pet();
        pet1.setId(1L);
        Pet pet2 = new Pet();
        pet2.setId(2L);
        List<Pet> pets = List.of(pet1, pet2);

        when(petRepository.findAll()).thenReturn(pets);

        // Act
        List<Long> result = petService.getAllPetIds();

        // Assert
        assertThat(result)
                .hasSize(2)
                .containsExactly(1L, 2L);
    }

    @Test
    void getAllShelterPets_WhenNoPets_ShouldReturnEmptyList() {
        // Arrange
        Long shelterId = 1L;
        when(petRepository.findByShelterId(shelterId)).thenReturn(Optional.empty());

        // Act
        List<PetResponse> result = petService.getAllShelterPets(shelterId);

        // Assert
        assertThat(result).isEmpty();
    }

    @Test
    void createPet_WithValidData_ShouldReturnCreatedPet() throws IOException {
        // Arrange
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("NewPet");
        Shelter shelter = new Shelter();
        Pet pet = new Pet();
        Pet savedPet = new Pet();
        savedPet.setId(1L);
        PetResponse expectedResponse = createPetResponse(1L, "NewPet", PetType.DOG);

        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(petMapper.toEntityWithShelter(petRequest, shelter)).thenReturn(pet);
        when(multipartFile.getOriginalFilename()).thenReturn("image.jpg");
        when(multipartFile.getContentType()).thenReturn("image/jpeg");
        when(multipartFile.getBytes()).thenReturn(new byte[10]);
        when(petRepository.save(pet)).thenReturn(savedPet);
        when(petMapper.toDto(savedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.createPet(petRequest, shelterId, multipartFile);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(petRepository).save(pet);
        assertThat(pet.getImageName()).isEqualTo("image.jpg");
        assertThat(pet.getImageType()).isEqualTo("image/jpeg");
        assertThat(pet.getImageData()).hasSize(10);
    }

    @Test
    void createPet_WhenShelterNotFound_ShouldThrowException() {
        // Arrange
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("NewPet");

        when(shelterRepository.findById(shelterId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> petService.createPet(petRequest, shelterId, multipartFile))
                .isInstanceOf(ShelterNotFoundException.class)
                .hasMessageContaining(shelterId.toString());
    }

    @Test
    void getPetImage_WhenPetExists_ShouldReturnImageResponse() {
        // Arrange
        Long petId = 1L;
        Pet pet = new Pet();
        pet.setImageName("image.jpg");
        pet.setImageType("image/jpeg");
        pet.setImageData(new byte[10]);
        PetImageResponse expectedResponse = new PetImageResponse(
                "image.jpg",
                "image/jpeg",
                Base64.getEncoder().encodeToString(new byte[10]));

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act
        PetImageResponse result = petService.getPetImage(petId);

        // Assert
        assertThat(result)
                .isNotNull()
                .extracting(PetImageResponse::imageName, PetImageResponse::imageType)
                .containsExactly("image.jpg", "image/jpeg");
        assertThat(result.imageData()).isBase64();
    }

    @Test
    void getPetImage_WhenPetNotExists_ShouldThrowException() {
        // Arrange
        Long petId = 1L;
        when(petRepository.findById(petId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> petService.getPetImage(petId))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void updatePet_WithValidData_ShouldReturnUpdatedPet() throws IOException {
        // Arrange
        Long petId = 1L;
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("UpdatedPet");
        Pet existingPet = new Pet();
        Shelter shelter = new Shelter();
        Pet updatedPet = new Pet();
        updatedPet.setId(petId);
        PetResponse expectedResponse = createPetResponse(petId, "UpdatedPet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(existingPet));
        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(multipartFile.getOriginalFilename()).thenReturn("new_image.jpg");
        when(multipartFile.getContentType()).thenReturn("image/jpeg");
        when(multipartFile.getBytes()).thenReturn(new byte[20]);
        when(petRepository.save(existingPet)).thenReturn(updatedPet);
        when(petMapper.toDto(updatedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.updatePet(petRequest, petId, shelterId, multipartFile);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(petRepository).save(existingPet);
        assertThat(existingPet.getName()).isEqualTo("UpdatedPet");
        assertThat(existingPet.getImageName()).isEqualTo("new_image.jpg");
    }

    @Test
    void updatePet_WithoutNewImage_ShouldKeepExistingImage() throws IOException {
        // Arrange
        Long petId = 1L;
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("UpdatedPet");
        Pet existingPet = new Pet();
        existingPet.setImageName("old_image.jpg");
        existingPet.setImageType("image/jpeg");
        existingPet.setImageData(new byte[10]);
        Shelter shelter = new Shelter();
        Pet updatedPet = new Pet();
        updatedPet.setId(petId);
        PetResponse expectedResponse = createPetResponse(petId, "UpdatedPet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(existingPet));
        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(petRepository.save(existingPet)).thenReturn(updatedPet);
        when(petMapper.toDto(updatedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.updatePet(petRequest, petId, shelterId, null);

        // Assert
        assertThat(result).isEqualTo(expectedResponse);
        assertThat(existingPet.getImageName()).isEqualTo("old_image.jpg");
        assertThat(existingPet.getImageData()).hasSize(10);
    }

    @Test
    void deletePet_WhenPetExists_ShouldDeletePet() {
        // Arrange
        Long petId = 1L;
        Pet pet = new Pet();
        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act
        petService.deletePet(petId);

        // Assert
        verify(petRepository).delete(pet);
    }

    @Test
    void deletePet_WhenPetNotExists_ShouldThrowException() {
        // Arrange
        Long petId = 1L;
        when(petRepository.findById(petId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> petService.deletePet(petId))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining(petId.toString());
    }

    @Test
    void archivePet_WhenPetExists_ShouldReturnArchivedPet() {
        // Arrange
        Long petId = 1L;
        Pet pet = new Pet();
        pet.setArchived(false);
        Pet archivedPet = new Pet();
        archivedPet.setArchived(true);
        PetResponse expectedResponse = createPetResponse(petId, "ArchivedPet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(petRepository.save(pet)).thenReturn(archivedPet);
        when(petMapper.toDto(archivedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.archivePet(petId);

        // Assert
        assertThat(result).isEqualTo(expectedResponse);
        assertThat(pet.isArchived()).isTrue();
    }

    private PetRequest createPetRequest(String name) {
        return new PetRequest(
                name,
                PetType.DOG,
                "Breed",
                2,
                "Description",
                Gender.MALE,
                PetSize.MEDIUM,
                true,
                false,
                true,
                true
        );
    }

    private PetResponse createPetResponse(Long id, String name, PetType type) {
        return new PetResponse(
                id,
                name,
                type,
                "Breed",
                2,
                false,
                "Description",
                1L,
                Gender.MALE,
                PetSize.MEDIUM,
                true,
                false,
                true,
                true,
                null,
                null,
                null
        );
    }
}