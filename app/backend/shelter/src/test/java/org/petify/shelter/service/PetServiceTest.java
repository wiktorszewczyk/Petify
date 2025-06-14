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
    private StorageService storageService;

    @Mock
    private MultipartFile multipartFile;

    @InjectMocks
    private PetService petService;

    private static final String TEST_IMAGE_NAME = "test-image.jpg";
    private static final String TEST_IMAGE_URL = "https://storage.example.com/test-image.jpg";

    @BeforeEach
    void setUp() {
        reset(petRepository, shelterRepository, favoritePetRepository,
                petMapper, storageService, multipartFile);
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
    void getPets_ShouldReturnListOfPetResponsesWithImages() {
        // Arrange
        Pet pet1 = createTestPet(1L, "Pet1", PetType.DOG);
        Pet pet2 = createTestPet(2L, "Pet2", PetType.CAT);
        List<Pet> pets = List.of(pet1, pet2);

        PetResponseWithImages response1 = createPetResponseWithImages(1L, "Pet1", PetType.DOG);
        PetResponseWithImages response2 = createPetResponseWithImages(2L, "Pet2", PetType.CAT);

        when(petRepository.findAll()).thenReturn(pets);
        when(petMapper.toDtoWithImages(pet1)).thenReturn(response1);
        when(petMapper.toDtoWithImages(pet2)).thenReturn(response2);

        // Act
        List<PetResponseWithImages> result = petService.getPets();

        // Assert
        assertThat(result)
                .hasSize(2)
                .containsExactly(response1, response2);
    }

    @Test
    void getFilteredPets_WhenNoPetsMatchCriteria_ShouldReturnEmptyList() {
        // Arrange
        when(favoritePetRepository.findByUsername(anyString())).thenReturn(Collections.emptyList());
        when(petRepository.findAll(any(Specification.class))).thenReturn(Collections.emptyList());

        // Act
        var result = petService.getFilteredPets(
                true, false, true, true,
                1, 5, PetType.DOG, 50.0, 20.0, 10.0, "user1");

        // Assert
        assertThat(result).isEmpty();
    }

    @Test
    void getPetById_WhenPetExists_ShouldReturnPetResponseWithImages() {
        // Arrange
        Long petId = 1L;
        Pet pet = createTestPet(petId, "Test Pet", PetType.DOG);
        PetResponseWithImages expectedResponse = createPetResponseWithImages(petId, "Test Pet", PetType.DOG);

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
        Pet pet1 = createTestPet(1L, "Pet1", PetType.DOG);
        Pet pet2 = createTestPet(2L, "Pet2", PetType.CAT);
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
    void createPet_WithValidDataAndImage_ShouldReturnCreatedPet() throws IOException {
        // Arrange
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("New Pet");
        Shelter shelter = new Shelter();
        shelter.setId(shelterId);

        Pet pet = new Pet();
        Pet savedPet = createTestPet(1L, "New Pet", PetType.DOG);
        PetResponse expectedResponse = createPetResponse(1L, "New Pet", PetType.DOG);

        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(petMapper.toEntityWithShelter(petRequest, shelter)).thenReturn(pet);
        when(multipartFile.isEmpty()).thenReturn(false);
        when(storageService.uploadImage(multipartFile)).thenReturn(TEST_IMAGE_NAME);
        when(petRepository.save(pet)).thenReturn(savedPet);
        when(petMapper.toDto(savedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.createPet(petRequest, shelterId, multipartFile);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(storageService).uploadImage(multipartFile);
        assertThat(pet.getImageName()).isEqualTo(TEST_IMAGE_NAME);
    }

    @Test
    void createPet_WithoutImage_ShouldCreatePetWithoutImage() throws IOException {
        // Arrange
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("New Pet");
        Shelter shelter = new Shelter();
        shelter.setId(shelterId);

        Pet pet = new Pet();
        Pet savedPet = createTestPet(1L, "New Pet", PetType.DOG);
        PetResponse expectedResponse = createPetResponse(1L, "New Pet", PetType.DOG);

        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(petMapper.toEntityWithShelter(petRequest, shelter)).thenReturn(pet);
        when(petRepository.save(pet)).thenReturn(savedPet);
        when(petMapper.toDto(savedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.createPet(petRequest, shelterId, null);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(storageService, never()).uploadImage(any());
        assertThat(pet.getImageName()).isNull();
    }

    @Test
    void createPet_WhenShelterNotFound_ShouldThrowException() {
        // Arrange
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("New Pet");

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
        Pet pet = createTestPet(petId, "Test Pet", PetType.DOG);
        pet.setImageName(TEST_IMAGE_NAME);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act
        PetImageResponse result = petService.getPetImage(petId);

        // Assert
        assertThat(result)
                .isNotNull()
                .extracting(PetImageResponse::imageUrl)
                .isEqualTo(TEST_IMAGE_NAME);
    }

    @Test
    void updatePet_WithNewImage_ShouldUpdatePetAndImage() throws IOException {
        // Arrange
        Long petId = 1L;
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("Updated Pet");
        Pet existingPet = createTestPet(petId, "Original Pet", PetType.DOG);
        existingPet.setImageName("old-image.jpg");
        Shelter shelter = new Shelter();
        shelter.setId(shelterId);

        Pet updatedPet = createTestPet(petId, "Updated Pet", PetType.DOG);
        updatedPet.setImageName(TEST_IMAGE_NAME);
        PetResponse expectedResponse = createPetResponse(petId, "Updated Pet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(existingPet));
        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(multipartFile.isEmpty()).thenReturn(false);
        when(storageService.uploadImage(multipartFile)).thenReturn(TEST_IMAGE_NAME);
        when(petRepository.save(existingPet)).thenReturn(updatedPet);
        when(petMapper.toDto(updatedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.updatePet(petRequest, petId, shelterId, multipartFile);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(storageService).uploadImage(multipartFile);
        assertThat(existingPet.getImageName()).isEqualTo(TEST_IMAGE_NAME);
    }

    @Test
    void updatePet_WithoutNewImage_ShouldKeepExistingImage() throws IOException {
        // Arrange
        Long petId = 1L;
        Long shelterId = 1L;
        PetRequest petRequest = createPetRequest("Updated Pet");
        Pet existingPet = createTestPet(petId, "Original Pet", PetType.DOG);
        existingPet.setImageName("existing-image.jpg");
        Shelter shelter = new Shelter();
        shelter.setId(shelterId);

        Pet updatedPet = createTestPet(petId, "Updated Pet", PetType.DOG);
        PetResponse expectedResponse = createPetResponse(petId, "Updated Pet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(existingPet));
        when(shelterRepository.findById(shelterId)).thenReturn(Optional.of(shelter));
        when(petRepository.save(existingPet)).thenReturn(updatedPet);
        when(petMapper.toDto(updatedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.updatePet(petRequest, petId, shelterId, null);

        // Assert
        assertThat(result)
                .isNotNull()
                .isEqualTo(expectedResponse);

        verify(storageService, never()).uploadImage(any());
        assertThat(existingPet.getImageName()).isEqualTo("existing-image.jpg");
    }

    @Test
    void deletePet_WhenPetExists_ShouldDeletePet() {
        // Arrange
        Long petId = 1L;
        Pet pet = createTestPet(petId, "Test Pet", PetType.DOG);
        pet.setImageName(TEST_IMAGE_NAME);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));

        // Act
        petService.deletePet(petId);

        // Assert
        verify(petRepository).delete(pet);
    }

    @Test
    void archivePet_WhenPetExists_ShouldArchivePet() {
        // Arrange
        Long petId = 1L;
        Pet pet = createTestPet(petId, "Test Pet", PetType.DOG);
        pet.setArchived(false);

        Pet archivedPet = createTestPet(petId, "Test Pet", PetType.DOG);
        archivedPet.setArchived(true);
        PetResponse expectedResponse = createPetResponse(petId, "Test Pet", PetType.DOG);

        when(petRepository.findById(petId)).thenReturn(Optional.of(pet));
        when(petRepository.save(pet)).thenReturn(archivedPet);
        when(petMapper.toDto(archivedPet)).thenReturn(expectedResponse);

        // Act
        PetResponse result = petService.archivePet(petId);

        // Assert
        assertThat(result).isEqualTo(expectedResponse);
        assertThat(pet.isArchived()).isTrue();
    }

    private Pet createTestPet(Long id, String name, PetType type) {
        Pet pet = new Pet();
        pet.setId(id);
        pet.setName(name);
        pet.setType(type);
        pet.setShelter(new Shelter());
        return pet;
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
                TEST_IMAGE_URL
        );
    }

    private PetResponseWithImages createPetResponseWithImages(Long id, String name, PetType type) {
        return new PetResponseWithImages(
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
                TEST_IMAGE_URL,
                Collections.emptyList()
        );
    }
}