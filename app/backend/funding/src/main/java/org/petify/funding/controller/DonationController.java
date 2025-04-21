package org.petify.funding.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.service.DonationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/donations")
@RequiredArgsConstructor
public class DonationController {

    private final DonationService donationService;

    /**
     * Get all donations.
     */
    @GetMapping
    public List<DonationResponse> getAll() {
        return donationService.getAllDonations();
    }

    /**
     * Get a single donation by its ID.
     */
    @GetMapping("/{id}")
    public DonationResponse getById(@PathVariable Long id) {
        return donationService.getDonationById(id);
    }

    /**
     * Get all donations made to a specific shelter.
     */
    @GetMapping("/shelter/{shelterId}")
    public List<DonationResponse> getByShelter(@PathVariable Long shelterId) {
        return donationService.getDonationsForShelter(shelterId);
    }

    /**
     * Get all donations made to a specific pet.
     */
    @GetMapping("/pet/{petId}")
    public List<DonationResponse> getByPet(@PathVariable Long petId) {
        return donationService.getDonationsForPet(petId);
    }

    /**
     * Create a new donation of any subtype.
     */
    @PostMapping
    public ResponseEntity<DonationResponse> create(
            @RequestBody @Valid DonationRequest request
    ) {
        DonationResponse created = donationService.createDonation(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(created);
    }

    /**
     * Delete an existing donation by ID.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        donationService.deleteDonation(id);
        return ResponseEntity.noContent().build();
    }
}
