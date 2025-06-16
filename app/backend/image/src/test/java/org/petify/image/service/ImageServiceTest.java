package org.petify.image.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.image.dto.ImageResponse;
import org.petify.image.exception.ImageNotFoundException;
import org.petify.image.exception.MaxImagesReachedException;
import org.petify.image.mapper.ImageMapper;
import org.petify.image.model.Image;
import org.petify.image.repository.ImageRepository;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ImageServiceTest {

    @Mock
    private ImageRepository imageRepository;

    @Mock
    private ImageMapper imageMapper;

    @Mock
    private StorageService storageService;

    @InjectMocks
    private ImageService imageService;

    @Test
    void getImageById_WhenExists_ReturnsImage() {
        Long imageId = 1L;
        Image image = new Image();
        ImageResponse response = new ImageResponse(imageId, 1L, "PET", "url.jpg", LocalDateTime.now());

        when(imageRepository.findById(imageId)).thenReturn(Optional.of(image));
        when(imageMapper.toDto(image)).thenReturn(response);

        ImageResponse result = imageService.getImageById(imageId);

        assertNotNull(result);
        assertEquals(imageId, result.id());
    }

    @Test
    void getImageById_WhenNotExists_ThrowsException() {
        Long imageId = 99L;
        when(imageRepository.findById(imageId)).thenReturn(Optional.empty());

        assertThrows(ImageNotFoundException.class, () -> imageService.getImageById(imageId));
    }

    @Test
    void getImagesByEntityId_ReturnsList() {
        Long entityId = 1L;
        String entityType = "PET";
        Image image = new Image();
        ImageResponse response = new ImageResponse(1L, entityId, entityType, "url.jpg", LocalDateTime.now());

        when(imageRepository.findAllByEntityIdAndEntityType(entityId, entityType)).thenReturn(List.of(image));
        when(imageMapper.toDto(image)).thenReturn(response);

        List<ImageResponse> result = imageService.getImagesByEntityId(entityId, entityType);

        assertEquals(1, result.size());
        assertEquals(entityId, result.get(0).entityId());
    }

    @Test
    void uploadImage_WhenUnderLimit_Success() throws IOException {
        Long entityId = 1L;
        String entityType = "PET";
        MultipartFile file = mock(MultipartFile.class);
        String storedFileName = "uuid.jpg";
        Image savedImage = new Image();
        ImageResponse response = new ImageResponse(1L, entityId, entityType, storedFileName, LocalDateTime.now());

        when(imageRepository.countByEntityIdAndEntityType(entityId, entityType)).thenReturn(0);
        when(storageService.uploadImage(file)).thenReturn(storedFileName);
        when(imageRepository.save(any(Image.class))).thenReturn(savedImage);
        when(imageMapper.toDto(savedImage)).thenReturn(response);

        ImageResponse result = imageService.uploadImage(entityId, entityType, file);

        assertNotNull(result);
        assertEquals(entityId, result.entityId());
    }

    @Test
    void uploadImage_WhenOverLimit_ThrowsException() {
        Long entityId = 1L;
        String entityType = "PET";
        MultipartFile file = mock(MultipartFile.class);

        when(imageRepository.countByEntityIdAndEntityType(entityId, entityType)).thenReturn(5);

        assertThrows(MaxImagesReachedException.class, 
            () -> imageService.uploadImage(entityId, entityType, file));
    }

    @Test
    void deleteImage_WhenExists_DeletesSuccessfully() {
        Long imageId = 1L;
        Image image = new Image();
        image.setImageName("test.jpg");

        when(imageRepository.findById(imageId)).thenReturn(Optional.of(image));
        when(storageService.deleteImage(image.getImageName())).thenReturn(true);

        assertDoesNotThrow(() -> imageService.deleteImage(imageId));
        verify(imageRepository).delete(image);
    }

    @Test
    void deleteImage_WhenNotExists_ThrowsException() {
        Long imageId = 99L;
        when(imageRepository.findById(imageId)).thenReturn(Optional.empty());

        assertThrows(ImageNotFoundException.class, () -> imageService.deleteImage(imageId));
    }

    @Test
    void uploadImages_MultipleFiles_Success() throws IOException {
        Long entityId = 1L;
        String entityType = "PET";
        MultipartFile file1 = mock(MultipartFile.class);
        MultipartFile file2 = mock(MultipartFile.class);
        List<MultipartFile> files = List.of(file1, file2);

        when(imageRepository.countByEntityIdAndEntityType(entityId, entityType)).thenReturn(0, 1);
        when(storageService.uploadImage(any(MultipartFile.class))).thenReturn("uuid1.jpg", "uuid2.jpg");
        when(imageRepository.save(any(Image.class))).thenReturn(new Image());
        when(imageMapper.toDto(any(Image.class))).thenReturn(
            new ImageResponse(1L, entityId, entityType, "uuid1.jpg", LocalDateTime.now()),
            new ImageResponse(2L, entityId, entityType, "uuid2.jpg", LocalDateTime.now())
        );

        List<ImageResponse> result = imageService.uploadImages(entityId, entityType, files);

        assertEquals(2, result.size());
    }
}
