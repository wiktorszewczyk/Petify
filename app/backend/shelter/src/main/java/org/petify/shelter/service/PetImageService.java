package org.petify.shelter.service;

import lombok.RequiredArgsConstructor;
import org.petify.shelter.dto.PetImageRequest;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.mapper.PetImageMapper;
import org.petify.shelter.model.PetImage;
import org.petify.shelter.repository.PetImageRepository;
import org.petify.shelter.repository.PetRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class PetImageService {
    private final PetImageRepository petImageRepository;
    private final PetRepository petRepository;
    private final PetImageMapper petImageMapper;

    public List<PetImageResponse> getImagesByPetId(Long petId) {
        return petImageRepository.findAllByPetId(petId).stream()
                .map(petImageMapper::toDto)
                .toList();
    }

    public void addPetImage(Long petId, PetImageRequest input) {
        petRepository.findById(petId)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found"));

        PetImage image = petImageMapper.toEntity(input);
        petImageRepository.save(image);
    }

    public boolean addPetImages(Long petId, List<PetImageRequest> images) {
        for (PetImageRequest input : images) {
            addPetImage(petId, input);
        }
        return true;
    }
}
