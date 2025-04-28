package org.petify.reservations.controller;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.service.ReservationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reservations")
@AllArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;

    @PostMapping("/slots")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<SlotResponse> createSlot(@Valid @RequestBody SlotRequest req) {
        SlotResponse created = reservationService.createSlot(req);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @DeleteMapping("/slots/{slotId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Void> deleteSlot(@PathVariable Long slotId) {
        reservationService.deleteSlot(slotId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/slots")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Void> deleteAllSlots() {
        reservationService.deleteAllSlots();
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/slots")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<SlotResponse>> getAllSlots() {
        return ResponseEntity.ok(reservationService.getAllSlots());
    }

    @GetMapping("/slots/pet/{petId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<SlotResponse>> getSlotsByPet(@PathVariable Long petId) {
        return ResponseEntity.ok(reservationService.getSlotsByPetId(petId));
    }

    @GetMapping("/slots/user/{username}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<SlotResponse>> getSlotsByUser(@PathVariable String username) {
        return ResponseEntity.ok(reservationService.getSlotsByUser(username));
    }

    @GetMapping("/my-slots")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<List<SlotResponse>> mySlots(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(reservationService.getSlotsByUser(jwt.getSubject()));
    }

    @PatchMapping("/slots/{slotId}/reserve")
    @PreAuthorize("hasAnyAuthority('ROLE_USER','ROLE_ADMIN')")
    public ResponseEntity<SlotResponse> reserveSlot(
            @PathVariable Long slotId,
            @AuthenticationPrincipal Jwt jwt) {

        SlotResponse reserved = reservationService.reserveSlot(slotId, jwt.getSubject());
        return ResponseEntity.ok(reserved);
    }

    @PatchMapping("/slots/{slotId}/cancel")
    @PreAuthorize("hasAnyAuthority('ROLE_USER','ROLE_ADMIN')")
    public ResponseEntity<SlotResponse> cancelReservation(
            @PathVariable Long slotId,
            @AuthenticationPrincipal Jwt jwt) {

        boolean isAdmin = jwt.getClaimAsStringList("roles")
                .contains("ROLE_ADMIN");

        SlotResponse cancelled =
                reservationService.cancelReservation(slotId, jwt.getSubject(), isAdmin);
        return ResponseEntity.ok(cancelled);
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PostMapping("/slots/batch")
    public ResponseEntity<List<SlotResponse>> createBatch(
            @Valid @RequestBody SlotBatchRequest req) {

        List<SlotResponse> created = reservationService.createBatchSlots(req);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }
}
