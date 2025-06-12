package org.petify.shelter.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.enums.AdoptionStatus;
import org.petify.shelter.exception.*;
import org.petify.shelter.mapper.AdoptionMapper;
import org.petify.shelter.model.Adoption;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.AdoptionRepository;
import org.petify.shelter.repository.PetRepository;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.security.access.AccessDeniedException;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdoptionServiceTest {

    @Mock
    private AdoptionRepository adoptionRepository;

    @Mock
    private ShelterRepository shelterRepository;

    @Mock
    private PetRepository petRepository;

    @Mock
    private AdoptionMapper adoptionMapper;

    @InjectMocks
    private AdoptionService adoptionService;

    private Pet testPet;
    private Shelter testShelter;
    private Adoption testAdoption;
    private AdoptionRequest testAdoptionRequest;
    private AdoptionResponse testAdoptionResponse;

    @BeforeEach
    void setUp() {
        testShelter = new Shelter();
        testShelter.setId(1L);
        testShelter.setOwnerUsername("shelter_owner");

        testPet = new Pet();
        testPet.setId(1L);
        testPet.setShelter(testShelter);
        testPet.setArchived(false);

        testAdoption = new Adoption();
        testAdoption.setId(1L);
        testAdoption.setUsername("test_user");
        testAdoption.setPet(testPet);
        testAdoption.setAdoptionStatus(AdoptionStatus.PENDING);

        testAdoptionRequest = new AdoptionRequest(
                "Motivation text",
                "Full Name",
                "123456789",
                "Test Address",
                "House",
                true,
                true,
                false,
                "Description"
        );

        testAdoptionResponse = new AdoptionResponse(
                1L,
                "test_user",
                1L,
                AdoptionStatus.PENDING,
                "Motivation text",
                "Full Name",
                "123456789",
                "Test Address",
                "House",
                true,
                true,
                false,
                "Description"
        );
    }

    @Test
    void createAdoptionForm_ShouldSuccessfullyCreateForm() {
        when(petRepository.findById(anyLong())).thenReturn(Optional.of(testPet));
        when(adoptionRepository.existsByPetIdAndUsername(anyLong(), anyString())).thenReturn(false);
        when(adoptionMapper.toEntity(any(AdoptionRequest.class))).thenReturn(testAdoption);
        when(adoptionRepository.save(any(Adoption.class))).thenReturn(testAdoption);
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        AdoptionResponse result = adoptionService.createAdoptionForm(1L, "test_user", testAdoptionRequest);

        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo(1L);
        assertThat(result.username()).isEqualTo("test_user");
        assertThat(result.petId()).isEqualTo(1L);
        assertThat(result.adoptionStatus()).isEqualTo(AdoptionStatus.PENDING);

        verify(petRepository).findById(1L);
        verify(adoptionRepository).existsByPetIdAndUsername(1L, "test_user");
        verify(adoptionRepository).save(testAdoption);
    }

    @Test
    void createAdoptionForm_ShouldThrowWhenPetNotFound() {
        when(petRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.createAdoptionForm(1L, "test_user", testAdoptionRequest))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining("1");

        verify(petRepository).findById(1L);
        verifyNoInteractions(adoptionRepository);
    }

    @Test
    void createAdoptionForm_ShouldThrowWhenPetIsArchived() {
        testPet.setArchived(true);
        when(petRepository.findById(anyLong())).thenReturn(Optional.of(testPet));

        assertThatThrownBy(() -> adoptionService.createAdoptionForm(1L, "test_user", testAdoptionRequest))
                .isInstanceOf(PetIsArchivedException.class)
                .hasMessageContaining("1");
    }

    @Test
    void createAdoptionForm_ShouldThrowWhenAdoptionAlreadyExists() {
        when(petRepository.findById(anyLong())).thenReturn(Optional.of(testPet));
        when(adoptionRepository.existsByPetIdAndUsername(anyLong(), anyString())).thenReturn(true);

        assertThatThrownBy(() -> adoptionService.createAdoptionForm(1L, "test_user", testAdoptionRequest))
                .isInstanceOf(AdoptionAlreadyExistsException.class)
                .hasMessageContaining("1")
                .hasMessageContaining("test_user");
    }

    @Test
    void getUserAdoptionForms_ShouldReturnUserForms() {
        when(adoptionRepository.findByUsername(anyString())).thenReturn(List.of(testAdoption));
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        List<AdoptionResponse> result = adoptionService.getUserAdoptionForms("test_user");

        assertThat(result).hasSize(1);

        verify(adoptionRepository).findByUsername("test_user");
    }

    @Test
    void getUserAdoptionForms_ShouldReturnEmptyListWhenNoForms() {
        when(adoptionRepository.findByUsername(anyString())).thenReturn(Collections.emptyList());

        List<AdoptionResponse> result = adoptionService.getUserAdoptionForms("test_user");

        assertThat(result).isEmpty();
    }

    @Test
    void getShelterAdoptionForms_ShouldReturnForms() {
        when(shelterRepository.findById(anyLong())).thenReturn(Optional.of(testShelter));
        when(adoptionRepository.findByPetShelter(any(Shelter.class))).thenReturn(List.of(testAdoption));
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        List<AdoptionResponse> result = adoptionService.getShelterAdoptionForms(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0)).isEqualTo(testAdoptionResponse);

        verify(shelterRepository).findById(1L);
        verify(adoptionRepository).findByPetShelter(testShelter);
    }

    @Test
    void getShelterAdoptionForms_ShouldThrowWhenShelterNotFound() {
        when(shelterRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.getShelterAdoptionForms(1L))
                .isInstanceOf(ShelterNotFoundException.class)
                .hasMessageContaining("1");
    }

    @Test
    void getPetAdoptionForms_ShouldReturnForms() {
        when(petRepository.findById(anyLong())).thenReturn(Optional.of(testPet));
        when(adoptionRepository.findByPet(any(Pet.class))).thenReturn(List.of(testAdoption));
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        List<AdoptionResponse> result = adoptionService.getPetAdoptionForms(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0)).isEqualTo(testAdoptionResponse);

        verify(petRepository).findById(1L);
        verify(adoptionRepository).findByPet(testPet);
    }

    @Test
    void getPetAdoptionForms_ShouldThrowWhenPetNotFound() {
        when(petRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.getPetAdoptionForms(1L))
                .isInstanceOf(PetNotFoundException.class)
                .hasMessageContaining("1");
    }
/*

    @Test
    void updateAdoptionStatus_ShouldSuccessfullyUpdateStatus() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));
        when(adoptionRepository.save(any(Adoption.class))).thenReturn(testAdoption);
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        AdoptionResponse result = adoptionService.updateAdoptionStatus(
                1L, AdoptionStatus.ACCEPTED, "shelter_owner");

        assertThat(result).isNotNull();
        assertThat(result.adoptionStatus()).isEqualTo(AdoptionStatus.ACCEPTED);

        verify(adoptionRepository).findById(1L);
        verify(adoptionRepository).save(testAdoption);
    }
*/

    @Test
    void updateAdoptionStatus_ShouldThrowWhenFormNotFound() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.updateAdoptionStatus(1L, AdoptionStatus.ACCEPTED, "shelter_owner"))
                .isInstanceOf(AdoptionFormNotFoundException.class)
                .hasMessageContaining("1");
    }

    @Test
    void updateAdoptionStatus_ShouldThrowWhenNotShelterOwner() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));

        assertThatThrownBy(() -> adoptionService.updateAdoptionStatus(1L, AdoptionStatus.ACCEPTED, "not_owner"))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("not allowed");
    }

    @Test
    void updateAdoptionStatus_ShouldArchivePetWhenAccepted() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));
        when(adoptionRepository.findByPetAndAdoptionStatusAndIdNot(any(Pet.class), any(AdoptionStatus.class), anyLong()))
                .thenReturn(Collections.emptyList());
        when(adoptionRepository.save(any(Adoption.class))).thenReturn(testAdoption);
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        AdoptionResponse result = adoptionService.updateAdoptionStatus(
                1L, AdoptionStatus.ACCEPTED, "shelter_owner");

        assertThat(result).isNotNull();
        assertThat(testPet.isArchived()).isTrue();

        verify(petRepository).save(testPet);
    }

    @Test
    void updateAdoptionStatus_ShouldRejectOtherFormsWhenAccepted() {
        Adoption otherAdoption = new Adoption();
        otherAdoption.setId(2L);
        otherAdoption.setAdoptionStatus(AdoptionStatus.PENDING);

        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));
        when(adoptionRepository.findByPetAndAdoptionStatusAndIdNot(any(Pet.class), any(AdoptionStatus.class), anyLong()))
                .thenReturn(List.of(otherAdoption));
        when(adoptionRepository.save(any(Adoption.class))).thenReturn(testAdoption);
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        AdoptionResponse result = adoptionService.updateAdoptionStatus(
                1L, AdoptionStatus.ACCEPTED, "shelter_owner");

        assertThat(result).isNotNull();
        assertThat(otherAdoption.getAdoptionStatus()).isEqualTo(AdoptionStatus.REJECTED);

        verify(adoptionRepository).save(otherAdoption);
    }

/*
@Test
void cancelAdoptionForm_ShouldSuccessfullyCancelForm() {
    when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));
    when(adoptionRepository.save(any(Adoption.class))).thenReturn(testAdoption);
    when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

    AdoptionResponse result = adoptionService.cancelAdoptionForm(1L, "test_user");

    assertThat(result).isNotNull();
    assertThat(result.adoptionStatus()).isEqualTo(AdoptionStatus.CANCELLED);

    verify(adoptionRepository).findById(1L);
    verify(adoptionRepository).save(testAdoption);
}*/

    @Test
    void cancelAdoptionForm_ShouldThrowWhenFormNotFound() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.cancelAdoptionForm(1L, "test_user"))
                .isInstanceOf(AdoptionFormNotFoundException.class)
                .hasMessageContaining("1");
    }

    @Test
    void cancelAdoptionForm_ShouldThrowWhenNotFormOwner() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));

        assertThatThrownBy(() -> adoptionService.cancelAdoptionForm(1L, "other_user"))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("own");
    }

    @Test
    void cancelAdoptionForm_ShouldThrowWhenNotPending() {
        testAdoption.setAdoptionStatus(AdoptionStatus.ACCEPTED);
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));

        assertThatThrownBy(() -> adoptionService.cancelAdoptionForm(1L, "test_user"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("pending");
    }

    @Test
    void getAdoptionFormById_ShouldReturnForm() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.of(testAdoption));
        when(adoptionMapper.toDto(any(Adoption.class))).thenReturn(testAdoptionResponse);

        AdoptionResponse result = adoptionService.getAdoptionFormById(1L);

        assertThat(result).isEqualTo(testAdoptionResponse);

        verify(adoptionRepository).findById(1L);
    }

    @Test
    void getAdoptionFormById_ShouldThrowWhenFormNotFound() {
        when(adoptionRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adoptionService.getAdoptionFormById(1L))
                .isInstanceOf(AdoptionFormNotFoundException.class)
                .hasMessageContaining("1");
    }
}