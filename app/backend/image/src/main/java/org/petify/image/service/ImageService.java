package org.petify.image.service;

import org.petify.image.dto.ImageResponse;
import org.petify.image.exception.ImageNotFoundException;
import org.petify.image.exception.MaxImagesReachedException;
import org.petify.image.mapper.ImageMapper;
import org.petify.image.model.Image;
import org.petify.image.repository.ImageRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@RequiredArgsConstructor
@Service
public class ImageService {
    private final ImageRepository imageRepository;
    private final ImageMapper imageMapper;
    private final StorageService storageService;

    public ImageResponse getImageById(Long imageId) {
        Image image = imageRepository.findById(imageId)
                .orElseThrow(() -> new ImageNotFoundException(imageId));
        return imageMapper.toDto(image);
    }

    public List<ImageResponse> getImagesByEntityId(Long entityId, String entityType) {
        return imageRepository.findAllByEntityIdAndEntityType(entityId, entityType).stream()
                .map(imageMapper::toDto)
                .toList();
    }

    @Transactional
    public ImageResponse uploadImage(Long entityId, String entityType, MultipartFile file) throws IOException {
        int currentImageCount = imageRepository.countByEntityIdAndEntityType(entityId, entityType);
        if (currentImageCount >= 5) {
            throw new MaxImagesReachedException(entityId, entityType);
        }

        String storedFileName = storageService.uploadImage(file);

        Image image = new Image();
        image.setEntityId(entityId);
        image.setEntityType(entityType);
        image.setImageName(storedFileName);

        Image savedImage = imageRepository.save(image);
        return imageMapper.toDto(savedImage);
    }

    @Transactional
    public List<ImageResponse> uploadImages(Long entityId, String entityType, List<MultipartFile> images) throws IOException {
        List<ImageResponse> savedImages = new ArrayList<>();
        for (MultipartFile image : images) {
            savedImages.add(uploadImage(entityId, entityType, image));
        }
        return savedImages;
    }

    @Transactional
    public void deleteImage(Long imageId) {
        Image image = imageRepository.findById(imageId)
                .orElseThrow(() -> new ImageNotFoundException(imageId));

        storageService.deleteImage(image.getImageName());

        imageRepository.delete(image);
    }
}
