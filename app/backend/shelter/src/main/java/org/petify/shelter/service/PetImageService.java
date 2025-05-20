package org.petify.shelter.service;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.exception.PetMaxImagesReachedException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.mapper.PetImageMapper;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.PetImage;
import org.petify.shelter.repository.PetImageRepository;
import org.petify.shelter.repository.PetRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
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

    public void addPetImages(Long petId, List<MultipartFile> images) throws IOException {
        for (MultipartFile input : images) {
            addPetImage(petId, input);
        }
    }

    private void addPetImage(Long petId, MultipartFile file) throws IOException {
        Pet pet = petRepository.findById(petId)
                .orElseThrow(() -> new PetNotFoundException(petId));

        int currentImageCount = petImageRepository.countByPetId(petId);
        if (currentImageCount >= 5) {
            throw new PetMaxImagesReachedException(petId);
        }

        PetImage petImage = new PetImage();
        petImage.setPet(pet);
        petImage.setImageName(file.getOriginalFilename());
        petImage.setImageType(file.getContentType());
        petImage.setImageData(file.getBytes());

        petImageRepository.save(petImage);
    }

    public void deletePetImage(Long imageId) {
        petImageRepository.deleteById(imageId);
    }
}
