package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.*;
import org.petify.shelter.model.Pet;
import org.petify.shelter.service.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/pets")
public class PetController {
    private final PetService petService;
    private final AdoptionService adoptionService;
    private final ShelterService shelterService;
    private final FavoritePetService favoritePetService;
    private final PetImageService petImageService;

    @GetMapping()
    public ResponseEntity<?> pets() {
        return ResponseEntity.ok(petService.getPets());
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PostMapping()
    public ResponseEntity<?> addPet(@Valid @RequestPart PetRequest petRequest,
                                    @RequestPart MultipartFile imageFile,
                                    @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterByOwnerUsername(username);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
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

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PutMapping("/{id}")
    public ResponseEntity<PetResponse> updatePet(
            @PathVariable Long id,
            @Valid @RequestPart PetRequest petRequest,
            @RequestPart(value = "imageFile", required = false) MultipartFile imageFile,
            @AuthenticationPrincipal Jwt jwt) throws IOException {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterByOwnerUsername(username);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        PetResponse updatedPet = petService.updatePet(petRequest, id, shelter.id(), imageFile);
        return ResponseEntity.ok(updatedPet);
    }

    @GetMapping("/{id}/image")
    public ResponseEntity<?> getPetImage(
            @PathVariable("id") Long id) {
        PetImageResponse petImageData = petService.getPetImage(id);

        return ResponseEntity.ok()
                .contentType(MediaType.valueOf(petImageData.imageType()))
                .body(Base64.getEncoder().encodeToString(petImageData.base64Image().getBytes()));
    }

    @GetMapping("/{petId}/images")
    public ResponseEntity<List<PetImageResponse>> getPetImages(
            @PathVariable("petId") Long petId) {
        List<PetImageResponse> images = petImageService.getImagesByPetId(petId);
        return ResponseEntity.ok(images);
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePet(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterByOwnerUsername(username);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        petService.deletePet(id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @GetMapping("/{id}/adoptions")
    public ResponseEntity<List<AdoptionResponse>> getPetAdoptionForms(@PathVariable Long id) {

        List<AdoptionResponse> forms = adoptionService.getPetAdoptionForms(id);
        return ResponseEntity.ok(forms);
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archivePet(
            @PathVariable("id") Long id,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterByOwnerUsername(username);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        PetResponse petResponse = petService.archivePet(id);
        return ResponseEntity.ok(petResponse);
    }

    @PreAuthorize("hasAuthority('ROLE_USER')")
    @PostMapping("/{id}/adopt")
    public ResponseEntity<AdoptionResponse> adoptPet(
            @PathVariable("id") Long petId,
            @Valid @RequestPart AdoptionRequest adoptionRequest,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;

        AdoptionResponse adoptionForm = adoptionService.createAdoptionForm(petId, username, adoptionRequest);
        return new ResponseEntity<>(adoptionForm, HttpStatus.CREATED);
    }

    @PreAuthorize("hasAuthority('ROLE_USER')")
    @PostMapping("/{id}/like")
    public ResponseEntity<?> likePet(
            @PathVariable("id") Long petId,
            @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        if (favoritePetService.save(username, petId)) {
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @PreAuthorize("hasAuthority('ROLE_USER')")
    @DeleteMapping("/{id}/dislike")
    public ResponseEntity<?> dislikePet(
            @PathVariable("id") Long petId,
            @AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        if (favoritePetService.delete(username, petId)) {
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @PreAuthorize("hasAuthority('ROLE_USER')")
    @GetMapping("/favorites")
    public ResponseEntity<?> getFavoritePets(@AuthenticationPrincipal Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;

        List<Pet> favoritePets = favoritePetService.getFavoritePets(username);
        return ResponseEntity.ok(favoritePets);
    }
}
