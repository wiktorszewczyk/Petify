package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.*;
import org.petify.shelter.service.AdoptionService;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/pets")
public class PetController {
    private final PetService petService;
    private final AdoptionService adoptionService;
    private final ShelterService shelterService;

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
    public ResponseEntity<?> getPetImage(@PathVariable("id") Long id) {
        PetImageResponse petImageData = petService.getPetImage(id);

        return ResponseEntity.ok()
                .contentType(MediaType.valueOf(petImageData.imageType()))
                .body(petImageData.imageData());
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
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;

        AdoptionResponse adoptionForm = adoptionService.createAdoptionForm(petId, username);
        return new ResponseEntity<>(adoptionForm, HttpStatus.CREATED);
    }
}
