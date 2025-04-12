package org.petify.shelter.controller;

import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionFormResponse;
import org.petify.shelter.model.AdoptionStatus;
import org.petify.shelter.service.AdoptionFormService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/adoption-forms")
@AllArgsConstructor
public class AdoptionFormController {
    private final AdoptionFormService adoptionFormService;

    @GetMapping("/{id}")
    public ResponseEntity<AdoptionFormResponse> getAdoptionForm(@PathVariable Long id) {
        AdoptionFormResponse form = adoptionFormService.getAdoptionFormById(id);
        return ResponseEntity.ok(form);
    }

    @PatchMapping("/{id}/cancel")
    public ResponseEntity<AdoptionFormResponse> cancelAdoptionForm(
            @PathVariable Long id,
            @RequestAttribute("userId") Integer userId) {

        AdoptionFormResponse cancelledForm = adoptionFormService.cancelAdoptionForm(id, userId);
        return ResponseEntity.ok(cancelledForm);
    }

    @PatchMapping("/adoption-forms/{id}/status")
    public ResponseEntity<AdoptionFormResponse> updateAdoptionStatus(
            @PathVariable Long id,
            @RequestParam AdoptionStatus status,
            @RequestAttribute("userId") Integer shelterOwnerId) {

        AdoptionFormResponse updatedForm = adoptionFormService.updateAdoptionStatus(id, status, shelterOwnerId);
        return ResponseEntity.ok(updatedForm);
    }
}
