package org.petify.shelter.controller;

import jakarta.persistence.EntityNotFoundException;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.RoutingException;
import org.petify.shelter.service.AdoptionService;
import org.petify.shelter.service.PetService;
import org.petify.shelter.service.ShelterService;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

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

    @GetMapping("/{id}/owner")
    @PreAuthorize("hasAnyRole('USER', 'SHELTER', 'ADMIN')")
    public ResponseEntity<String> owner(@PathVariable Long id) {
        return ResponseEntity.ok(petService.getOwnerUsernameByPetId(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PostMapping()
    public ResponseEntity<?> addShelter(
            @Valid @RequestPart ShelterRequest shelterRequest,
            @RequestPart(value = "imageFile", required = false) MultipartFile imageFile,
            @AuthenticationPrincipal Jwt jwt) throws IOException {

        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.createShelter(shelterRequest, imageFile, username);

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

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PutMapping("/{id}")
    public ResponseEntity<?> updateShelter(@PathVariable("id") Long id,
                                           @Valid @RequestPart ShelterRequest shelterRequest,
                                           @RequestPart(value = "imageFile", required = false) MultipartFile imageFile,
                                           @AuthenticationPrincipal Jwt jwt) throws IOException {

        verifyShelterOwnership(id, jwt);

        ShelterResponse updatedShelter = shelterService.updateShelter(shelterRequest, imageFile, id);
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

    @GetMapping("/{shelterId}/route")
    public ResponseEntity<?> shelterRoute(
            @PathVariable Long shelterId,
            @RequestParam(required = true) @Min(-90) @Max(90) Double latitude,
            @RequestParam(required = true) @Min(-180) @Max(180) Double longitude) {

        try {
            ShelterResponse shelter = shelterService.getShelterById(shelterId);

            if (shelter == null) {
                return ResponseEntity.notFound().build();
            }

            if (shelter.latitude() == null || shelter.longitude() == null) {
                return ResponseEntity.badRequest().body(
                        Map.of("error", "Shelter has invalid coordinates"));
            }

            String routeJson = shelterService.getRouteToShelter(latitude, longitude, shelter);

            new ObjectMapper().readTree(routeJson);

            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(routeJson);

        } catch (IOException | InterruptedException e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Routing service unavailable"));
        } catch (RoutingException e) {
            throw new RuntimeException(e);
        }
    }

    private void verifyShelterOwnership(Long shelterId, Jwt jwt) {
        String username = jwt != null ? jwt.getSubject() : null;
        ShelterResponse shelter = shelterService.getShelterById(shelterId);

        if (!shelter.ownerUsername().equals(username)) {
            throw new AccessDeniedException("You are not the owner of this shelter");
        }
    }

    /**
     * Sprawdza czy schronisko istnieje i jest aktywne
     */
    @GetMapping("/{shelterId}/validate")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<Void> validateShelter(@PathVariable Long shelterId) {
        HttpStatus status = shelterService.validateShelterForDonations(shelterId);
        return ResponseEntity.status(status).build();
    }

    /**
     * Sprawdza czy zwierzę istnieje w danym schronisku i czy można na nie wpłacać
     */
    @GetMapping("/{shelterId}/pets/{petId}/validate")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<Void> validatePetInShelter(
            @PathVariable Long shelterId,
            @PathVariable Long petId) {

        HttpStatus status = petService.validatePetForDonations(shelterId, petId);
        return ResponseEntity.status(status).build();
    }
}
