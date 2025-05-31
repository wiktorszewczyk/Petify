package org.petify.funding.controller;

import org.petify.funding.dto.*;
import org.petify.funding.service.DonationService;
import org.petify.funding.service.PaymentService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/donations")
@RequiredArgsConstructor
@Slf4j
public class DonationController {

    private final DonationService donationService;
    private final PaymentService paymentService;

    /**
     * Create donation and return payment options
     */
    @PostMapping("/create")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationWithPaymentOptions> createDonation(
            @RequestBody @Valid DonationRequest request,
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String userCountry) {

        if (request.getDonorUsername() == null && jwt != null) {
            request.setDonorUsername(jwt.getSubject());
        }

        log.info("Creating donation for user: {}", request.getDonorUsername());

        DonationResponse donation = donationService.create(request);

        var paymentOptions = paymentService.getAvailablePaymentOptions(donation.getId(), userCountry);

        DonationWithPaymentOptions response = DonationWithPaymentOptions.builder()
                .donation(donation)
                .availablePaymentOptions(paymentOptions)
                .activePayment(null)
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Create donation and immediately create payment
     */
    @PostMapping("/create-with-payment")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationWithPaymentOptions> createDonationWithPayment(
            @RequestBody @Valid CreateDonationWithPaymentRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        if (request.getDonationRequest().getDonorUsername() == null && jwt != null) {
            request.getDonationRequest().setDonorUsername(jwt.getSubject());
        }

        log.info("Creating donation with immediate payment for user: {}",
                request.getDonationRequest().getDonorUsername());

        DonationResponse donation = donationService.create(request.getDonationRequest());

        PaymentRequest paymentRequest = PaymentRequest.builder()
                .donationId(donation.getId())
                .preferredProvider(request.getPreferredProvider())
                .preferredMethod(request.getPreferredMethod())
                .currency(donation.getCurrency())
                .amount(donation.getAmount())
                .customerUsername(donation.getDonorUsername())
                .description("Donation to animal shelter")
                .build();

        PaymentResponse payment = paymentService.createPayment(paymentRequest);

        var paymentOptions = paymentService.getAvailablePaymentOptions(donation.getId(), null);

        DonationWithPaymentOptions response = DonationWithPaymentOptions.builder()
                .donation(donation)
                .availablePaymentOptions(paymentOptions)
                .activePayment(payment)
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Page<DonationResponse>> getAllDonations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) org.petify.funding.model.DonationType type) {

        Page<DonationResponse> donations = donationService.getAll(
                PageRequest.of(page, size, Sort.by("donatedAt").descending()),
                type
        );
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<DonationResponse> getDonationById(@PathVariable Long id) {
        DonationResponse donation = donationService.get(id);
        return ResponseEntity.ok(donation);
    }

    @GetMapping("/shelter/{shelterId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Page<DonationResponse>> getDonationsByShelter(
            @PathVariable Long shelterId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getForShelter(
                shelterId,
                PageRequest.of(page, size, Sort.by("donatedAt").descending())
        );
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/pet/{petId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Page<DonationResponse>> getDonationsByPet(
            @PathVariable Long petId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getForPet(
                petId,
                PageRequest.of(page, size, Sort.by("donatedAt").descending())
        );
        return ResponseEntity.ok(donations);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public void deleteDonation(@PathVariable Long id) {
        donationService.delete(id);
    }
}