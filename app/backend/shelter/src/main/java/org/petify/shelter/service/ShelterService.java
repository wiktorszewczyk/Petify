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
    private ShelterRepository shelterRepository;

    public List<ShelterResponse> getShelters() {
        List<Shelter> shelters = shelterRepository.findAll();
        List<ShelterResponse> shelterResponses = new ArrayList<>();
        for (Shelter shelter : shelters) {
            shelterResponses.add(new ShelterResponse(shelter.getId(), shelter.getOwnerId(), shelter.getName(),
                    shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()));
        }

        return shelterResponses;
    }

    public ShelterResponse getShelterById(Long id) {
        return shelterRepository.findById(id)
                .map(shelter -> new ShelterResponse(shelter.getId(), shelter.getOwnerId(), shelter.getName(),
                        shelter.getDescription(), shelter.getAddress(), shelter.getPhoneNumber()))
                .orElseThrow(() -> new EntityNotFoundException("Shelter with id " + id + " not found"));
    }

    @Transactional
    public ShelterResponse createShelter(ShelterRequest input) {
        Shelter shelter = new Shelter(input.ownerId(), input.name(), input.description(), input.address(), input.phoneNumber());
        Shelter savedShelter = shelterRepository.save(shelter);
        return new ShelterResponse(savedShelter.getId(), savedShelter.getOwnerId(), savedShelter.getName(),
                savedShelter.getDescription(), savedShelter.getAddress(), savedShelter.getPhoneNumber());
    }
}
