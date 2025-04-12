package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.PetImageResponse;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.dto.PetResponse;
import org.petify.shelter.service.PetService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@AllArgsConstructor
@RestController
@RequestMapping("/pets")
public class PetController {
    private PetService petService;

    @GetMapping("/")
    public ResponseEntity<?> pets() {
        return ResponseEntity.ok(petService.getPets());
    }

    @PostMapping("/")
    public ResponseEntity<?> addPet(@Valid @RequestPart PetRequest pet,
                                    @RequestPart MultipartFile imageFile) {
        // Narazie przykladowo dla jednego wybranego schroniska, pozniej do edycji, by z automatu principal brało id schroniska zalogowanego
        Long shelterId = 4L;
        try {
            PetResponse pet1 = petService.createPet(pet, shelterId, imageFile);
            return new ResponseEntity<>(pet1, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPetById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(petService.getPetById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updatePet(@PathVariable("id") Long id,
                                       @Valid @RequestBody PetRequest input) {
        return (ResponseEntity<?>) ResponseEntity.ok();
    }

    @GetMapping("/{id}/image")
    public ResponseEntity<?> getPetImage(@PathVariable("id") Long id) {
        PetImageResponse petImageData = petService.getPetImage(id);

        return ResponseEntity.ok()
                .contentType(MediaType.valueOf(petImageData.imageType()))
                .body(petImageData.imageData());
    }
}
