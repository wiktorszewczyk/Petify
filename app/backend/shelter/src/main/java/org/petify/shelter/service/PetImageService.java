package org.petify.shelter.service;

import lombok.RequiredArgsConstructor;
import org.petify.shelter.dto.PetImageRequest;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.repository.PetImageRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class PetImageService {
    private final PetImageRepository petImageRepository;

    public List<PetImageResponse> getImagesByPetId(Long petId) {
        return petImageRepository.findAllByPetId(petId).stream()
                .map(image -> new PetImageResponse(image.getImageName(), image.getImageType(), image.getImageData()))
                .toList();
    }

    public boolean addImage(Long petId, PetImageRequest input) {

    }
}
