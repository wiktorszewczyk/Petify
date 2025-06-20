package org.petify.reservations.controller;

import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.service.ReservationService;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/reservations")
@AllArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    @PostMapping("/slots")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<SlotResponse> createSlot(@Valid @RequestBody SlotRequest req) {
        SlotResponse created = reservationService.createSlot(req);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @PostMapping("/slots/batch")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<List<SlotResponse>> createBatch(@Valid @RequestBody SlotBatchRequest req) {
        List<SlotResponse> created = reservationService.createBatchSlots(req);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @DeleteMapping("/slots/{slotId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<Void> deleteSlot(@PathVariable Long slotId) {
        reservationService.deleteSlot(slotId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/slots")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<Void> deleteAllSlots() {
        reservationService.deleteAllSlots();
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/slots")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<List<SlotResponse>> getAllSlots() {
        return ResponseEntity.ok(reservationService.getAllSlots());
    }

    @GetMapping("/slots/available")
    @PreAuthorize("hasAnyRole('ADMIN', 'VOLUNTEER')")
    public ResponseEntity<List<SlotResponse>> getAvailableSlots() {
        return ResponseEntity.ok(reservationService.getAvailableSlots());
    }

    @GetMapping("/slots/pet/{petId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER', 'VOLUNTEER')")
    public ResponseEntity<List<SlotResponse>> getSlotsByPet(@PathVariable Long petId) {
        return ResponseEntity.ok(reservationService.getSlotsByPetId(petId));
    }

    @GetMapping("/slots/user/{username}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<List<SlotResponse>> getSlotsByUser(@PathVariable String username) {
        return ResponseEntity.ok(reservationService.getSlotsByUser(username));
    }

    @GetMapping("/my-slots")
    @PreAuthorize("hasRole('VOLUNTEER')")
    public ResponseEntity<List<SlotResponse>> mySlots(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(reservationService.getSlotsByUser(jwt.getSubject()));
    }

    @PatchMapping("/slots/{slotId}/reserve")
    @PreAuthorize("hasAnyRole('VOLUNTEER', 'ADMIN', 'SHELTER')")
    public ResponseEntity<SlotResponse> reserveSlot(
            @PathVariable Long slotId,
            @AuthenticationPrincipal Jwt jwt) {

        SlotResponse reserved = reservationService.reserveSlot(slotId, jwt.getSubject());
        return ResponseEntity.ok(reserved);
    }

    @PatchMapping("/slots/{slotId}/cancel")
    @PreAuthorize("hasAnyRole('VOLUNTEER', 'ADMIN', 'SHELTER')")
    public ResponseEntity<SlotResponse> cancelReservation(
            @PathVariable Long slotId,
            @AuthenticationPrincipal Jwt jwt) {

        SlotResponse cancelled = reservationService.cancelReservation(slotId, jwt.getSubject(), jwt.getClaimAsStringList("roles"));
        return ResponseEntity.ok(cancelled);
    }

    @PatchMapping("/{slotId}/reactivate")
    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    public ResponseEntity<SlotResponse> reactivateSlot(
            @PathVariable Long slotId,
            @AuthenticationPrincipal Jwt jwt) {

        SlotResponse response = reservationService.reactivateCancelledSlot(slotId, jwt.getClaimAsStringList("roles"));
        return ResponseEntity.ok(response);
    }
}
