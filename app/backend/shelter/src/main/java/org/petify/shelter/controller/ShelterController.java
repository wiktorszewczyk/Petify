package org.petify.shelter.controller;

import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.service.AdoptionService;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PostMapping()
    public ResponseEntity<?> addShelter(
            @Valid @RequestBody ShelterRequest input,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.createShelter(input, username);

        return new ResponseEntity<>(shelter, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getShelterById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(shelterService.getShelterById(id));
    }

    @GetMapping("/{id}/pets")
    public ResponseEntity<?> getPetsByShelterId(@PathVariable("id") Long id) {
        return ResponseEntity.ok(petService.getAllShelterPets(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PutMapping("/{id}")
    public ResponseEntity<?> updateShelter(@PathVariable("id") Long id,
                                           @Valid @RequestBody ShelterRequest input,
                                           @AuthenticationPrincipal Jwt jwt) {

        verifyShelterOwnership(id, jwt);

        ShelterResponse updatedShelter = shelterService.updateShelter(input, id);
        return ResponseEntity.ok(updatedShelter);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteShelter(@PathVariable("id") Long id,
                                           @AuthenticationPrincipal Jwt jwt) {

        verifyShelterOwnership(id, jwt);

        shelterService.deleteShelter(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @GetMapping("/{id}/adoptions")
    public ResponseEntity<List<AdoptionResponse>> getShelterAdoptionForms(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt) {

        verifyShelterOwnership(id, jwt);

        List<AdoptionResponse> forms = adoptionService.getShelterAdoptionForms(id);
        return ResponseEntity.ok(forms);
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{shelterId}/activate")
    public ResponseEntity<?> activateShelter(@PathVariable Long shelterId) {
        shelterService.activateShelter(shelterId);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{shelterId}/deactivate")
    public ResponseEntity<?> deactivateShelter(@PathVariable Long shelterId) {
        shelterService.deactivateShelter(shelterId);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    private void verifyShelterOwnership(Long shelterId, Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterById(shelterId);

        if (!shelter.ownerUsername().equals(username)) {
            throw new AccessDeniedException("You are not the owner of this shelter");
        }
    }
}
