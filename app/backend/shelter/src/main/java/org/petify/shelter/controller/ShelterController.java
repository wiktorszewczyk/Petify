package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/shelters")
public class ShelterController {
    private ShelterService shelterService;
    private PetService petService;

    @GetMapping()
    public ResponseEntity<List<?>> getShelters() {
        return ResponseEntity.ok(shelterService.getShelters());
    }

    @PostMapping()
    public ResponseEntity<?> addShelter(@Valid @RequestBody ShelterRequest input) {
        return ResponseEntity.ok(shelterService.createShelter(input));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getShelterById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(shelterService.getShelterById(id));
    }

    @GetMapping("/{id}/pets")
    public ResponseEntity<?> getPetsByShelterId(@PathVariable("id") Long id) {
        return ResponseEntity.ok(petService.getAllShelterPets(id));
    }
}
