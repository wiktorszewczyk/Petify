package org.petify.shelter.controller;

import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.enums.AdoptionStatus;
import org.petify.shelter.service.AdoptionService;

import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/adoptions")
@AllArgsConstructor
public class AdoptionController {
    private final AdoptionService adoptionService;

    @GetMapping("/{id}")
    public ResponseEntity<AdoptionResponse> getAdoptionForm(
            @PathVariable Long id) {
        AdoptionResponse form = adoptionService.getAdoptionFormById(id);
        return ResponseEntity.ok(form);
    }

    @PreAuthorize("hasAnyRole('USER', 'VOLUNTEER', 'ADMIN')")
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<AdoptionResponse> cancelAdoptionForm(
            @PathVariable Long id,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;

        AdoptionResponse cancelledForm = adoptionService.cancelAdoptionForm(id, username);
        return ResponseEntity.ok(cancelledForm);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PatchMapping("/{id}/status")
    public ResponseEntity<AdoptionResponse> updateAdoptionStatus(
            @PathVariable Long id,
            @RequestParam AdoptionStatus status,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;

        AdoptionResponse updatedForm = adoptionService.updateAdoptionStatus(id, status, username);
        return ResponseEntity.ok(updatedForm);
    }
}
