package org.petify.shelter.controller;

import org.petify.shelter.dto.AdoptionRequest;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.enums.PetType;
import org.petify.shelter.service.AdoptionService;
import org.petify.shelter.service.FavoritePetService;
import org.petify.shelter.service.PetImageService;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/pets")
public class PetController {
    private final PetService petService;
    private final AdoptionService adoptionService;
    private final ShelterService shelterService;
    private final FavoritePetService favoritePetService;
    private final PetImageService petImageService;

    @GetMapping()
    public ResponseEntity<?> getAllPets() {
        return ResponseEntity.ok(petService.getPets());
    }

    @GetMapping("/filter")
    public ResponseEntity<List<PetResponse>> getFilteredPets(
            @RequestParam(required = false) Boolean vaccinated,
            @RequestParam(required = false) Boolean urgent,
            @RequestParam(required = false) Boolean sterilized,
            @RequestParam(required = false) Boolean kidFriendly,
            @RequestParam(required = false) Integer minAge,
            @RequestParam(required = false) Integer maxAge,
            @RequestParam(required = false) PetType type,
            @RequestParam(required = false) Double userLat,
            @RequestParam(required = false) Double userLng,
            @RequestParam(required = false) Double radiusKm
    ) {
        return ResponseEntity.ok(
                petService.getFilteredPets(vaccinated, urgent, sterilized, kidFriendly, minAge, maxAge, type, userLat, userLng, radiusKm)
        );
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PostMapping()
    public ResponseEntity<?> addPet(@Valid @RequestPart PetRequest petRequest,
                                    @RequestPart MultipartFile imageFile,
                                    @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterByOwnerUsername(username);

        if (!shelter.ownerUsername().equals(username)) {
            throw new AccessDeniedException("You are not the owner of this shelter");
        }

        try {
            PetResponse pet = petService.createPet(petRequest, shelter.id(), imageFile);
            return new ResponseEntity<>(pet, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPetById(@PathVariable("id") Long id) {
        return new ResponseEntity<>(petService.getPetById(id), HttpStatus.FOUND);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PutMapping("/{id}")
    public ResponseEntity<PetResponse> updatePet(
            @PathVariable Long id,
            @Valid @RequestPart PetRequest petRequest,
            @RequestPart(value = "imageFile", required = false) MultipartFile imageFile,
            @AuthenticationPrincipal Jwt jwt) throws IOException {

        verifyPetOwnership(id, jwt);

        Long shelterId = petService.getPetById(id).shelterId();

        PetResponse updatedPet = petService.updatePet(petRequest, id, shelterId, imageFile);
        return ResponseEntity.ok(updatedPet);
    }

    @GetMapping("/{id}/image")
    public ResponseEntity<?> getPetImage(
            @PathVariable("id") Long id) {
        PetImageResponse petImageData = petService.getPetImage(id);

        return ResponseEntity.ok()
                .contentType(MediaType.valueOf(petImageData.imageType()))
                .body(Base64.getEncoder().encodeToString(petImageData.imageData().getBytes(StandardCharsets.UTF_8)));
    }

    @GetMapping("/{petId}/images")
    public ResponseEntity<List<PetImageResponse>> getPetImages(
            @PathVariable("petId") Long petId) {
        List<PetImageResponse> images = petImageService.getImagesByPetId(petId);
        return ResponseEntity.ok(images);
    }

    @PostMapping("/{petId}/images")
    public ResponseEntity<?> uploadMultiplePetImages(
            @PathVariable("petId") Long petId,
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("images") List<MultipartFile> files) throws IOException {

        verifyPetOwnership(petId, jwt);

        if (files.isEmpty()) {
            return new ResponseEntity<>("No files send.", HttpStatus.BAD_REQUEST);
        }

        petImageService.addPetImages(petId, files);

        return new ResponseEntity<>(HttpStatus.CREATED);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{petId}/images/{imageId}")
    public ResponseEntity<?> deleteImage(
            @PathVariable("petId") Long petId,
            @PathVariable("imageId") Long imageId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        verifyPetOwnership(petId, jwt);

        petImageService.deletePetImage(imageId);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePet(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal Jwt jwt) {

        verifyPetOwnership(id, jwt);

        petService.deletePet(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @GetMapping("/{id}/adoptions")
    public ResponseEntity<List<AdoptionResponse>> getPetAdoptionForms(@PathVariable Long id) {

        List<AdoptionResponse> forms = adoptionService.getPetAdoptionForms(id);
        return new ResponseEntity<>(forms, HttpStatus.OK);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archivePet(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal Jwt jwt) {

        verifyPetOwnership(id, jwt);

        PetResponse petResponse = petService.archivePet(id);
        return new ResponseEntity<>(petResponse, HttpStatus.OK);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @PostMapping("/{id}/adopt")
    public ResponseEntity<AdoptionResponse> adoptPet(
            @PathVariable("id") Long petId,
            @Valid @RequestBody AdoptionRequest adoptionRequest,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;

        AdoptionResponse adoptionForm = adoptionService.createAdoptionForm(petId, username, adoptionRequest);
        return new ResponseEntity<>(adoptionForm, HttpStatus.CREATED);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @PostMapping("/{id}/like")
    public ResponseEntity<?> likePet(
            @PathVariable("id") Long petId,
            @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        favoritePetService.like(username, petId);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @PostMapping("/{id}/dislike")
    public ResponseEntity<?> dislikePet(
            @PathVariable("id") Long petId,
            @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        favoritePetService.dislike(username, petId);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @PostMapping("/{id}/support")
    public ResponseEntity<?> supportPet(
            @PathVariable("id") Long petId,
            @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        if (username == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        favoritePetService.support(username, petId);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @GetMapping("/favorites")
    public ResponseEntity<?> getFavoritePets(@AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        List<PetResponse> favoritePets = favoritePetService.getFavoritePets(username);
        return ResponseEntity.ok(favoritePets);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @GetMapping("/supportedPets")
    public ResponseEntity<?> getSupportedPets(@AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        List<PetResponse> favoritePets = favoritePetService.getSupportedPets(username);
        return ResponseEntity.ok(favoritePets);
    }

    private void verifyPetOwnership(Long petId, @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;
        Long shelterId = petService.getPetById(petId).shelterId();
        ShelterResponse shelter = shelterService.getShelterById(shelterId);

        if (!shelter.ownerUsername().equals(username)) {
            throw new AccessDeniedException("You are not the owner of this pet!");
        }
    }
}
