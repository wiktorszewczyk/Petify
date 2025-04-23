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

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class ShelterService {
    private final ShelterRepository shelterRepository;
    private final ShelterMapper shelterMapper;

    public List<ShelterResponse> getShelters() {
        List<Shelter> shelters = shelterRepository.findAll();

        return shelters.stream().map(shelterMapper::toDto).collect(Collectors.toList());
    }

    public ShelterResponse getShelterById(Long shelterId) {
        return shelterRepository.findById(shelterId)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));
    }

    public ShelterResponse getShelterByOwnerUsername(String username) {
        return shelterRepository.getShelterByOwnerUsername(username)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterByOwnerNotFoundException(username));
    }

    public ShelterResponse getShelterByOwnerUsername(String username) {
        return shelterRepository.getShelterByOwnerUsername(username)
                .map(shelter -> new ShelterResponse(shelter.getId(), shelter.getOwnerUsername(), shelter.getName(),
                        shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()))
                .orElseThrow(() -> new EntityNotFoundException("No shelter connected to user: " + username + " found!"));
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
    public void deleteShelter(Long shelterId) {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        shelterRepository.delete(shelter);
    }

    public void activateShelter(Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setIsActive(true);
        shelterRepository.save(existingShelter);
    }

    public void deactivateShelter(Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setIsActive(false);
        shelterRepository.save(existingShelter);
    }
}
