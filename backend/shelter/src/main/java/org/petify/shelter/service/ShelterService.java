package org.petify.shelter.service;

import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
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
            shelterResponses.add(new ShelterResponse(shelter.getId(), shelter.getName()));
        }

        return shelterResponses;
    }

    @Transactional
    public Shelter createShelter(ShelterRequest input) {
        Shelter shelter = new Shelter();
        shelter.setName(input.name());
        return shelterRepository.save(shelter);
    }
}
