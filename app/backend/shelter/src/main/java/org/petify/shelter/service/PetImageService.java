package org.petify.shelter.service;

import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.exception.PetImageNotFoundException;
import org.petify.shelter.exception.PetMaxImagesReachedException;
import org.petify.shelter.exception.PetNotFoundException;
import org.petify.shelter.mapper.PetImageMapper;
import org.petify.shelter.model.Pet;
import org.petify.shelter.model.PetImage;
import org.petify.shelter.repository.PetImageRepository;
import org.petify.shelter.repository.PetRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RequiredArgsConstructor
@Service
public class PetImageService {
    private final PetImageRepository petImageRepository;
    private final PetRepository petRepository;
    private final PetImageMapper petImageMapper;
    private final StorageService storageService;

    @Transactional
    public List<PetImageResponse> getImagesByPetId(Long petId) {
        return petImageRepository.findAllByPetId(petId).stream()
                .map(petImageMapper::toDto)
                .toList();
    }

    @Transactional
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

        if (file != null && !file.isEmpty()) {
            String imageName = storageService.uploadImage(file);
            petImage.setImageName(imageName);
        }

        petImageRepository.save(petImage);
    }

    @Transactional
    public void deletePetImage(Long imageId) {
        PetImage image = petImageRepository.findById(imageId)
                        .orElseThrow(() -> new PetImageNotFoundException(imageId));

        Pet pet = image.getPet();

        if (storageService.deleteImage(pet.getImageName())) {
            pet.getImages().remove(image);
        }

        petRepository.save(pet);
    }
}
