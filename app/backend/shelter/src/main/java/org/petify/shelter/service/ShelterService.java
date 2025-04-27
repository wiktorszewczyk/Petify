package org.petify.shelter.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@AllArgsConstructor
@Service
public class ShelterService {
    private final ShelterRepository shelterRepository;

    public List<ShelterResponse> getShelters() {
        List<Shelter> shelters = shelterRepository.findAll();
        List<ShelterResponse> shelterResponses = new ArrayList<>();
        for (Shelter shelter : shelters) {
            shelterResponses.add(new ShelterResponse(shelter.getId(), shelter.getOwnerUsername(), shelter.getName(),
                    shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()));
        }

        return shelterResponses;
    }

    public ShelterResponse getShelterById(Long id) {
        return shelterRepository.findById(id)
                .map(shelter -> new ShelterResponse(shelter.getId(), shelter.getOwnerUsername(), shelter.getName(),
                        shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()))
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + id + " not found"));
    }

    public ShelterResponse getShelterByOwnerUsername(String username) {
        return shelterRepository.getShelterByOwnerUsername(username)
                .map(shelter -> new ShelterResponse(shelter.getId(), shelter.getOwnerUsername(), shelter.getName(),
                        shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()))
                .orElseThrow(() -> new EntityNotFoundException("No shelter connected to user: " + username + " found!"));
    }

    @Transactional
    public ShelterResponse createShelter(ShelterRequest input, String username) {
        Shelter shelter = new Shelter(username, input.name(), input.description(), input.address(), input.phoneNumber());
        Shelter savedShelter = shelterRepository.save(shelter);
        return new ShelterResponse(savedShelter.getId(), savedShelter.getOwnerUsername(), savedShelter.getName(),
                savedShelter.getDescription(), savedShelter.getAddress(), savedShelter.getPhoneNumber());
    }

    @Transactional
    public ShelterResponse updateShelter(ShelterRequest input, Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + shelterId + " not found!"));

        existingShelter.setName(input.name());
        existingShelter.setDescription(input.description());
        existingShelter.setAddress(input.address());
        existingShelter.setPhoneNumber(input.phoneNumber());

        Shelter updatedShelter = shelterRepository.save(existingShelter);

        return new ShelterResponse(
                updatedShelter.getId(),
                updatedShelter.getOwnerUsername(),
                updatedShelter.getName(),
                updatedShelter.getDescription(),
                updatedShelter.getAddress(),
                updatedShelter.getPhoneNumber()
        );
    }

    @Transactional
    public void deleteShelter(Long id) {
        Shelter shelter = shelterRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + id + " not found!"));

        shelterRepository.delete(shelter);
    }
}
