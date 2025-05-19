package org.petify.funding.controller;

import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.model.DonationType;
import org.petify.funding.service.DonationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * CRUD endpoints for donations (monetary and material), with pagination and optional type filtering.
 */
@RestController
@RequestMapping("/donations")
@RequiredArgsConstructor
@Validated
public class DonationController {

    private final DonationService donationService;

    /**
     * Retrieve a paginated list of donations, optionally filtered by type.
     */
    @GetMapping
    public Page<DonationResponse> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) DonationType type
    ) {
        var pageRequest = PageRequest.of(page, size, Sort.by("donatedAt").descending());
        return donationService.getAll(pageRequest, type);
    }

    /**
     * Retrieve a single donation by its ID.
     */
    @GetMapping("/{id}")
    public DonationResponse getById(@PathVariable Long id) {
        return donationService.get(id);
    }

    /**
     * Retrieve donations for a given shelter, paginated.
     */
    @GetMapping("/shelter/{shelterId}")
    public Page<DonationResponse> getByShelter(
            @PathVariable Long shelterId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        var pageRequest = PageRequest.of(page, size, Sort.by("donatedAt").descending());
        return donationService.getForShelter(shelterId, pageRequest);
    }

    /**
     * Retrieve donations for a given pet, paginated.
     */
    @GetMapping("/pet/{petId}")
    public Page<DonationResponse> getByPet(
            @PathVariable Long petId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        var pageRequest = PageRequest.of(page, size, Sort.by("donatedAt").descending());
        return donationService.getForPet(petId, pageRequest);
    }

    /**
     * Create a new donation (monetary or material).
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DonationResponse create(@RequestBody @Valid DonationRequest request) {
        return donationService.create(request);
    }

    /**
     * Delete a donation by its ID.
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        donationService.delete(id);
    }
}
