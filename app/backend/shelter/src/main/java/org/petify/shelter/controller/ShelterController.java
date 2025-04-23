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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
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

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PostMapping()
    public ResponseEntity<?> addShelter(
            @Valid @RequestBody ShelterRequest input,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.createShelter(input, username);

        return new ResponseEntity<>(shelter, HttpStatus.CREATED);
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
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
                                           @Valid @RequestBody ShelterRequest input,
                                           @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterById(id);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        ShelterResponse updatedShelter = shelterService.updateShelter(input, id);
        return ResponseEntity.ok(updatedShelter);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteShelter(@PathVariable("id") Long id,
                                           @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterById(id);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        shelterService.deleteShelter(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/adoptions")
    public ResponseEntity<List<AdoptionResponse>> getShelterAdoptionForms(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterById(id);

        if (!shelter.ownerUsername().equals(username)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        List<AdoptionResponse> forms = adoptionService.getShelterAdoptionForms(id);
        return ResponseEntity.ok(forms);
    }
}
