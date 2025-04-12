package org.petify.shelter.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.service.AdoptionService;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/shelters")
public class ShelterController {
    private final ShelterService shelterService;
    private final PetService petService;
    private final AdoptionService adoptionService;

    @GetMapping()
    public ResponseEntity<List<?>> getShelters() {
        return ResponseEntity.ok(shelterService.getShelters());
    }

    @PostMapping()
    public ResponseEntity<?> addShelter(@Valid @RequestBody ShelterRequest input) {
        return new ResponseEntity<>(shelterService.createShelter(input), HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getShelterById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(shelterService.getShelterById(id));
    }

    @GetMapping("/{id}/pets")
    public ResponseEntity<?> getPetsByShelterId(@PathVariable("id") Long id) {
        return ResponseEntity.ok(petService.getAllShelterPets(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateShelter(@PathVariable("id") Long id,
                                           @Valid @RequestBody ShelterRequest input) {

        ShelterResponse updatedShelter = shelterService.updateShelter(input, id);
        return ResponseEntity.ok(updatedShelter);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteShelter(@PathVariable("id") Long id) {
        shelterService.deleteShelter(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/adoptions")
    public ResponseEntity<List<AdoptionResponse>> getShelterAdoptionForms(
            @PathVariable Long id) {

        List<AdoptionResponse> forms = adoptionService.getShelterAdoptionForms(id);
        return ResponseEntity.ok(forms);
    }
}
