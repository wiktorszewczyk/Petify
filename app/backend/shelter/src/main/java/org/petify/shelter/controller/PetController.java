package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionFormResponse;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.service.AdoptionFormService;
import org.petify.shelter.service.PetService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/pets")
public class PetController {
    private final PetService petService;
    private final AdoptionFormService adoptionFormService;

    @GetMapping()
    public ResponseEntity<?> pets() {
        return ResponseEntity.ok(petService.getPets());
    }

    @PostMapping()
    public ResponseEntity<?> addPet(@Valid @RequestPart PetRequest petRequest,
                                    @RequestPart MultipartFile imageFile) {
        // Narazie przykladowo dla jednego wybranego schroniska, pozniej do edycji, by z automatu principal brało id schroniska zalogowanego
        Long shelterId = 1L;
        try {
            PetResponse pet = petService.createPet(petRequest, shelterId, imageFile);
            return new ResponseEntity<>(pet, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPetById(@PathVariable("id") Long id) {
        return new ResponseEntity<>(petService.getPetById(id), HttpStatus.FOUND);
    }

    @PutMapping("/{id}")
    public ResponseEntity<PetResponse> updatePet(
            @PathVariable Long id,
            @RequestPart("petRequest") PetRequest petRequest,
            @RequestPart(value = "imageFile", required = false) MultipartFile imageFile) throws IOException {

        // Narazie przykladowo dla jednego wybranego schroniska, pozniej do edycji, by z automatu principal brało id schroniska zalogowanego
        Long shelterId = 1L;

        PetResponse updatedPet = petService.updatePet(petRequest, id, shelterId, imageFile);
        return ResponseEntity.ok(updatedPet);
    }

    @GetMapping("/{id}/image")
    public ResponseEntity<?> getPetImage(@PathVariable("id") Long id) {
        PetImageResponse petImageData = petService.getPetImage(id);

        return ResponseEntity.ok()
                .contentType(MediaType.valueOf(petImageData.imageType()))
                .body(petImageData.imageData());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePet(@PathVariable("id") Long id) {
        petService.deletePet(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/adoption-forms")
    public ResponseEntity<List<AdoptionFormResponse>> getPetAdoptionForms(@PathVariable Long id) {

        List<AdoptionFormResponse> forms = adoptionFormService.getPetAdoptionForms(id);
        return ResponseEntity.ok(forms);
    }

    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archivePet(@PathVariable("id") Long id) {
        PetResponse petResponse = petService.archivePet(id);
        return ResponseEntity.ok(petResponse);
    }

    @PostMapping("/{id}/adopt")
    public ResponseEntity<AdoptionFormResponse> adoptPet(@PathVariable("id") Long petId) {

        // Przykladowo narazie, do poprawki na branie id z Principal
        Integer userId = 1;

        AdoptionFormResponse adoptionForm = adoptionFormService.createAdoptionForm(petId, userId);
        return new ResponseEntity<>(adoptionForm, HttpStatus.CREATED);
    }
}
