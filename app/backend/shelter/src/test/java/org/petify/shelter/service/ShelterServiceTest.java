package org.petify.shelter.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.ShelterAlreadyExistsException;
import org.petify.shelter.exception.ShelterByOwnerNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.ShelterMapper;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.ShelterRepository;

import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class ShelterServiceTest {

    @Mock
    private ShelterRepository shelterRepository;

    @Mock
    private ShelterMapper shelterMapper;

    @InjectMocks
    private ShelterService shelterService;

    private Shelter shelter;
    private ShelterRequest shelterRequest;
    private ShelterResponse shelterResponse;

    @BeforeEach
    void setUp() {
        shelter = new Shelter();
        shelter.setId(1L);
        shelter.setName("Shelter Name");
        shelter.setDescription("Description");
        shelter.setAddress("Address");
        shelter.setPhoneNumber("123456789");
        shelter.setLatitude(52.2297);
        shelter.setLongitude(21.0122);

        shelterRequest = new ShelterRequest(
                "Shelter Name",
                "Description",
                "Address",
                "123456789",
                52.2297,
                21.0122
        );

        shelterResponse = new ShelterResponse(
                1L,
                "ownerUsername",
                "Shelter Name",
                "Description",
                "Address",
                "123456789",
                52.2297,
                21.0122,
                true
        );
    }

    @Test
    void testGetShelters() {
        when(shelterRepository.findAll()).thenReturn(List.of(shelter));
        when(shelterMapper.toDto(any(Shelter.class))).thenReturn(shelterResponse);

        List<ShelterResponse> result = shelterService.getShelters();

        assertThat(result).hasSize(1);
        assertThat(result.get(0)).isEqualTo(shelterResponse);
    }

    @Test
    void testGetShelterById() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.of(shelter));
        when(shelterMapper.toDto(any(Shelter.class))).thenReturn(shelterResponse);

        ShelterResponse result = shelterService.getShelterById(1L);

        assertThat(result).isEqualTo(shelterResponse);
    }

    @Test
    void testGetShelterById_NotFound() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> shelterService.getShelterById(1L))
                .isInstanceOf(ShelterNotFoundException.class);
    }

    @Test
    void testGetShelterByOwnerUsername() {
        when(shelterRepository.getShelterByOwnerUsername("ownerUsername")).thenReturn(Optional.of(shelter));
        when(shelterMapper.toDto(any(Shelter.class))).thenReturn(shelterResponse);

        ShelterResponse result = shelterService.getShelterByOwnerUsername("ownerUsername");

        assertThat(result).isEqualTo(shelterResponse);
    }

    @Test
    void testGetShelterByOwnerUsername_NotFound() {
        when(shelterRepository.getShelterByOwnerUsername("ownerUsername")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> shelterService.getShelterByOwnerUsername("ownerUsername"))
                .isInstanceOf(ShelterByOwnerNotFoundException.class);
    }

    @Test
    void testCreateShelter() {
        when(shelterRepository.getShelterByOwnerUsername("ownerUsername")).thenReturn(Optional.empty());
        when(shelterMapper.toEntity(any(ShelterRequest.class))).thenReturn(shelter);
        when(shelterRepository.save(any(Shelter.class))).thenReturn(shelter);
        when(shelterMapper.toDto(any(Shelter.class))).thenReturn(shelterResponse);

        ShelterResponse result = shelterService.createShelter(shelterRequest, "ownerUsername");

        assertThat(result).isEqualTo(shelterResponse);
        verify(shelterRepository, times(1)).save(shelter);
    }

    @Test
    void testCreateShelter_AlreadyExists() {
        when(shelterRepository.getShelterByOwnerUsername("ownerUsername")).thenReturn(Optional.of(shelter));

        assertThatThrownBy(() -> shelterService.createShelter(shelterRequest, "ownerUsername"))
                .isInstanceOf(ShelterAlreadyExistsException.class);
    }

    @Test
    void testUpdateShelter() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.of(shelter));
        when(shelterRepository.save(any(Shelter.class))).thenReturn(shelter);
        when(shelterMapper.toDto(any(Shelter.class))).thenReturn(shelterResponse);

        ShelterResponse result = shelterService.updateShelter(shelterRequest, 1L);

        assertThat(result).isEqualTo(shelterResponse);
        verify(shelterRepository, times(1)).save(shelter);
    }

    @Test
    void testUpdateShelter_NotFound() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> shelterService.updateShelter(shelterRequest, 1L))
                .isInstanceOf(ShelterNotFoundException.class);
    }

    @Test
    void testDeleteShelter() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.of(shelter));

        shelterService.deleteShelter(1L);

        verify(shelterRepository, times(1)).delete(shelter);
    }

    @Test
    void testDeleteShelter_NotFound() {
        when(shelterRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> shelterService.deleteShelter(1L))
                .isInstanceOf(ShelterNotFoundException.class);
    }
}
