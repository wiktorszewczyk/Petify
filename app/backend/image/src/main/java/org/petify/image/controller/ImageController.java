package org.petify.image.controller;

import org.petify.image.dto.ImageResponse;
import org.petify.image.service.ImageService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/images")
public class ImageController {
    private final ImageService imageService;

    @GetMapping("/{imageId}")
    public ResponseEntity<ImageResponse> getImageById(
            @PathVariable Long imageId) {
        ImageResponse image = imageService.getImageById(imageId);
        return ResponseEntity.ok(image);
    }

    @GetMapping("/{entityType}/{entityId}/images")
    public ResponseEntity<List<ImageResponse>> getEntityImages(
            @PathVariable Long entityId,
            @PathVariable String entityType) {
        List<ImageResponse> images = imageService.getImagesByEntityId(entityId, entityType);
        return ResponseEntity.ok(images);
    }

    @PostMapping("/{entityType}/{entityId}/images")
    public ResponseEntity<?> uploadMultipleImages(
            @PathVariable Long entityId,
            @PathVariable String entityType,
            @RequestParam("images") List<MultipartFile> files) throws IOException {
        if (files.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }

        imageService.uploadImages(entityId, entityType, files);
        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{imageId}")
    public ResponseEntity<?> deleteImage(
            @PathVariable Long imageId,
            @AuthenticationPrincipal Jwt jwt) {

        imageService.deleteImage(imageId);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
