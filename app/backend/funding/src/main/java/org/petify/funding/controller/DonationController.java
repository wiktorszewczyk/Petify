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
     * Tworzy nową dotację wraz z płatnością (unified endpoint)
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationWithPaymentResponse> createDonation(
            @RequestBody @Valid DonationWithPaymentRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        enrichRequestWithUserData(request, jwt);

        log.info("Creating donation with payment for user: {}, provider: {}",
                request.getDonorUsername(), request.getPaymentProvider());

        // 1. Utwórz dotację
        DonationResponse donation = donationService.create(request.toDonationRequest());

        // 2. Utwórz płatność
        PaymentRequest paymentRequest = PaymentRequest.builder()
                .donationId(donation.getId())
                .preferredProvider(request.getPaymentProvider())
                .preferredMethod(request.getPaymentMethod())
                .returnUrl(request.getReturnUrl())
                .cancelUrl(request.getCancelUrl())
                .blikCode(request.getBlikCode())
                .bankCode(request.getBankCode())
                .build();

        PaymentResponse payment = paymentService.createPayment(paymentRequest);

        // 3. Oblicz opłaty
        PaymentService.PaymentFeeCalculation feeInfo = paymentService.calculatePaymentFee(
                donation.getAmount(), payment.getProvider());

        // 4. Zwróć wszystko
        DonationWithPaymentResponse response = DonationWithPaymentResponse.builder()
                .donation(donation)
                .payment(payment)
                .feeInformation(feeInfo)
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Endpoint dla powrotu z płatności - sprawdza status
     */
    @GetMapping("/payment-status/{donationId}")
    public ResponseEntity<DonationWithPaymentStatusResponse> checkPaymentStatus(
            @PathVariable Long donationId) {

        DonationResponse donation = donationService.get(donationId);

        var payments = paymentService.getPaymentsByDonation(donationId);
        PaymentResponse latestPayment = payments.isEmpty() ? null :
                payments.stream()
                        .max((p1, p2) -> p1.getCreatedAt().compareTo(p2.getCreatedAt()))
                        .orElse(null);

        DonationWithPaymentStatusResponse response = DonationWithPaymentStatusResponse.builder()
                .donation(donation)
                .latestPayment(latestPayment)
                .isCompleted(donation.getStatus() == org.petify.funding.model.DonationStatus.COMPLETED)
                .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Pobiera wszystkie dotacje (tylko admin)
     */
    @GetMapping
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Page<DonationResponse>> getAllDonations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) org.petify.funding.model.DonationType type) {

        Page<DonationResponse> donations = donationService.getAll(
                PageRequest.of(page, size, Sort.by("createdAt").descending()),
                type
        );
        return ResponseEntity.ok(donations);
    }

    /**
     * Pobiera dotacje użytkownika
     */
    @GetMapping("/my")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<Page<DonationResponse>> getMyDonations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getUserDonations(
                PageRequest.of(page, size, Sort.by("createdAt").descending())
        );
        return ResponseEntity.ok(donations);
    }

    /**
     * Pobiera konkretną dotację
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationResponse> getDonationById(@PathVariable Long id) {
        DonationResponse donation = donationService.get(id);
        return ResponseEntity.ok(donation);
    }

    /**
     * Pobiera dotacje dla schroniska (publiczne)
     */
    @GetMapping("/shelter/{shelterId}")
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

    /**
     * Pobiera dotacje dla zwierzęcia (publiczne)
     */
    @GetMapping("/pet/{petId}")
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

    /**
     * Pobiera statystyki dotacji dla schroniska
     */
    @GetMapping("/shelter/{shelterId}/stats")
    public ResponseEntity<DonationStatistics> getShelterStats(
            @PathVariable Long shelterId) {

        DonationStatistics stats = donationService.getShelterDonationStats(shelterId);
        return ResponseEntity.ok(stats);
    }

    /**
     * Usuwa dotację (tylko admin)
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public void deleteDonation(@PathVariable Long id) {
        donationService.delete(id);
    }

    /**
     * Oblicza opłaty za płatność przed utworzeniem
     */
    @PostMapping("/calculate-fees")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentService.PaymentFeeCalculation> calculateFees(
            @RequestBody CalculateFeesRequest request) {

        PaymentService.PaymentFeeCalculation calculation = paymentService.calculatePaymentFee(
                request.getAmount(),
                request.getProvider() != null ? request.getProvider() : org.petify.funding.model.PaymentProvider.PAYU
        );

        return ResponseEntity.ok(calculation);
    }

    private void enrichRequestWithUserData(DonationWithPaymentRequest request, Jwt jwt) {
        if (jwt != null) {
            if (request.getDonorUsername() == null) {
                request.setDonorUsername(jwt.getSubject());
            }
            if (request.getDonorId() == null && jwt.getClaim("userId") != null) {
                request.setDonorId(jwt.getClaim("userId"));
            }
        }
    }
}
