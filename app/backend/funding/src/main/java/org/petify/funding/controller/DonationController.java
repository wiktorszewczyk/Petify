package org.petify.funding.controller;

import org.petify.funding.dto.DonationIntentRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.dto.DonationStatistics;
import org.petify.funding.dto.DonationWithPaymentStatusResponse;
import org.petify.funding.dto.PaymentChoiceRequest;
import org.petify.funding.dto.PaymentInitializationResponse;
import org.petify.funding.dto.PaymentOptionsResponse;
import org.petify.funding.dto.PaymentProviderOption;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.Base64;
import java.util.List;

@RestController
@RequestMapping("/donations")
@RequiredArgsConstructor
@Slf4j
public class DonationController {

    private final DonationService donationService;
    private final PaymentService paymentService;

    @PostMapping("/intent")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentOptionsResponse> createDonationIntent(
            @RequestBody @Valid DonationIntentRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        log.info("Creating donation intent for user: {}", jwt.getSubject());

        DonationResponse donation = donationService.createDraft(request, jwt);

        List<PaymentProviderOption> options = paymentService.getAvailablePaymentOptions(
                donation.getAmount(), getCurrentUserLocation());

        String sessionToken = generateSessionToken(donation.getId());

        PaymentOptionsResponse response = PaymentOptionsResponse.builder()
                .donationId(donation.getId())
                .donation(donation)
                .availableProviders(options)
                .sessionToken(sessionToken)
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/{donationId}/payment/initialize")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentInitializationResponse> initializePayment(
            @PathVariable Long donationId,
            @RequestBody @Valid PaymentChoiceRequest request,
            @RequestHeader("Session-Token") String sessionToken) {

        log.info("Initializing payment for donation {} with provider {}",
                donationId, request.getProvider());

        validateSessionToken(sessionToken, donationId);

        PaymentInitializationResponse response = paymentService.initializePayment(
                donationId, request);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/payment-status/{donationId}")
    public ResponseEntity<DonationWithPaymentStatusResponse> checkPaymentStatus(
            @PathVariable Long donationId) {

        DonationResponse donation = donationService.get(donationId);

        List<PaymentResponse> payments = paymentService.getPaymentsByDonation(donationId);
        PaymentResponse latestPayment = payments.isEmpty() ? null :
                payments.stream()
                        .max((p1, p2) -> p1.getCreatedAt().compareTo(p2.getCreatedAt()))
                        .orElse(null);

        DonationWithPaymentStatusResponse response = DonationWithPaymentStatusResponse.builder()
                .donation(donation)
                .latestPayment(latestPayment)
                .isCompleted(donation.getStatus() == DonationStatus.COMPLETED)
                .build();

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{donationId}/cancel")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationResponse> cancelDonation(@PathVariable Long donationId) {
        DonationResponse donation = donationService.cancelDonation(donationId);
        return ResponseEntity.ok(donation);
    }

    @PostMapping("/{donationId}/refund")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<DonationResponse> refundDonation(
            @PathVariable Long donationId,
            @RequestParam(required = false) BigDecimal amount) {
        DonationResponse donation = donationService.refundDonation(donationId, amount);
        return ResponseEntity.ok(donation);
    }

    @GetMapping
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Page<DonationResponse>> getAllDonations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) DonationType type) {

        Page<DonationResponse> donations = donationService.getAll(
                PageRequest.of(page, size, Sort.by("createdAt").descending()), type);
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/my")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<Page<DonationResponse>> getMyDonations(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getUserDonations(
                PageRequest.of(page, size, Sort.by("createdAt").descending()));
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<DonationResponse> getDonationById(@PathVariable Long id) {
        DonationResponse donation = donationService.get(id);
        return ResponseEntity.ok(donation);
    }

    @GetMapping("/shelter/{shelterId}")
    public ResponseEntity<Page<DonationResponse>> getDonationsByShelter(
            @PathVariable Long shelterId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getForShelter(
                shelterId, PageRequest.of(page, size, Sort.by("donatedAt").descending()));
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/pet/{petId}")
    public ResponseEntity<Page<DonationResponse>> getDonationsByPet(
            @PathVariable Long petId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getForPet(
                petId, PageRequest.of(page, size, Sort.by("donatedAt").descending()));
        return ResponseEntity.ok(donations);
    }

    @GetMapping("/shelter/{shelterId}/stats")
    public ResponseEntity<DonationStatistics> getShelterStats(@PathVariable Long shelterId) {
        DonationStatistics stats = donationService.getShelterDonationStats(shelterId);
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/fundraiser/{fundraiserId}")
    public ResponseEntity<Page<DonationResponse>> getDonationsByFundraiser(
            @PathVariable Long fundraiserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Page<DonationResponse> donations = donationService.getForFundraiser(
                fundraiserId, PageRequest.of(page, size, Sort.by("donatedAt").descending()));
        return ResponseEntity.ok(donations);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public void deleteDonation(@PathVariable Long id) {
        donationService.delete(id);
    }

    private String getCurrentUserLocation() {
        return "PL";
    }

    private String generateSessionToken(Long donationId) {
        return Base64.getEncoder().encodeToString(
                (donationId + ":" + System.currentTimeMillis()).getBytes());
    }

    private void validateSessionToken(String sessionToken, Long donationId) {
        try {
            String decoded = new String(Base64.getDecoder().decode(sessionToken));
            String expectedPrefix = donationId + ":";

            if (!decoded.startsWith(expectedPrefix)) {
                throw new RuntimeException("Invalid session token");
            }

            long timestamp = Long.parseLong(decoded.substring(expectedPrefix.length()));
            long now = System.currentTimeMillis();

            if (now - timestamp > 30 * 60 * 1000) {
                throw new RuntimeException("Session token expired");
            }

        } catch (Exception e) {
            throw new RuntimeException("Invalid session token", e);
        }
    }
}
