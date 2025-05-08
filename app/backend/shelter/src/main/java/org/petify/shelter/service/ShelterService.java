package org.petify.shelter.service;

import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.ShelterAlreadyExistsException;
import org.petify.shelter.exception.ShelterByOwnerNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.ShelterMapper;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.ShelterRepository;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@AllArgsConstructor
@Service
public class ShelterService {
    private final ShelterRepository shelterRepository;
    private final ShelterMapper shelterMapper;

    public List<ShelterResponse> getShelters() {
        List<Shelter> shelters = shelterRepository.findAll();
        List<ShelterResponse> shelterResponses = new ArrayList<>();
        for (Shelter shelter : shelters) {
            shelterResponses.add(shelterMapper.toDto(shelter));
        }

        return shelterResponses;
    }

    public ShelterResponse getShelterById(Long id) {
        return shelterRepository.findById(id)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterNotFoundException(id));
    }

    public ShelterResponse getShelterByOwnerUsername(String username) {
        return shelterRepository.getShelterByOwnerUsername(username)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterByOwnerNotFoundException(username));
    }

    @Transactional
    public ShelterResponse createShelter(ShelterRequest input, String username) {
        if (shelterRepository.getShelterByOwnerUsername(username).isPresent()) {
            throw new ShelterAlreadyExistsException(username);
        }

        Shelter shelter = shelterMapper.toEntity(input);
        shelter.setOwnerUsername(username);
        Shelter savedShelter = shelterRepository.save(shelter);
        return shelterMapper.toDto(savedShelter);
    }

    @Transactional
    public ShelterResponse updateShelter(ShelterRequest input, Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setName(input.name());
        existingShelter.setDescription(input.description());
        existingShelter.setAddress(input.address());
        existingShelter.setPhoneNumber(input.phoneNumber());
        existingShelter.setLatitude(input.latitude());
        existingShelter.setLongitude(input.longitude());

        Shelter updatedShelter = shelterRepository.save(existingShelter);

        return shelterMapper.toDto(updatedShelter);
    }

    @Transactional
    public void deleteShelter(Long id) {
        Shelter shelter = shelterRepository.findById(id)
                .orElseThrow(() -> new ShelterNotFoundException(id));

        shelterRepository.delete(shelter);
    }
}
