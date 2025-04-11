package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.PetRequest;
import org.petify.shelter.service.PetService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
    public ResponseEntity<?> addPet(@Valid @RequestBody PetRequest input) {
        // Narazie przykladowo dla jednego wybranego schroniska, pozniej do edycji, by z automatu principal brało id schroniska zalogowanego
        Long shelterId = 4L;
        return ResponseEntity.ok(petService.createPet(input, shelterId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPetById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(petService.getPetById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updatePet(@PathVariable("id") Long id, @RequestBody PetRequest input) {
        return (ResponseEntity<?>) ResponseEntity.ok();
    }
}
