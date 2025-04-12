package org.petify.shelter.controller;

import lombok.AllArgsConstructor;
import org.petify.shelter.dto.AdoptionResponse;
import org.petify.shelter.model.AdoptionStatus;
import org.petify.shelter.service.AdoptionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/adoptions")
@AllArgsConstructor
public class AdoptionController {
    private final AdoptionService adoptionService;

    @GetMapping("/{id}")
    public ResponseEntity<AdoptionResponse> getAdoptionForm(@PathVariable Long id) {
        AdoptionResponse form = adoptionService.getAdoptionFormById(id);
        return ResponseEntity.ok(form);
    }

    @PatchMapping("/{id}/cancel")
    public ResponseEntity<AdoptionResponse> cancelAdoptionForm(
            @PathVariable Long id) {

        // Przykladowo narazie, do poprawki na branie id z Principal
        Integer userId = 1;

        AdoptionResponse cancelledForm = adoptionService.cancelAdoptionForm(id, userId);
        return ResponseEntity.ok(cancelledForm);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<AdoptionResponse> updateAdoptionStatus(
            @PathVariable Long id,
            @RequestParam AdoptionStatus status) {

        // Przykladowo narazie, do poprawki na branie id z Principal
        Integer shelterOwnerId = 1;

        AdoptionResponse updatedForm = adoptionService.updateAdoptionStatus(id, status, shelterOwnerId);
        return ResponseEntity.ok(updatedForm);
    }
}
