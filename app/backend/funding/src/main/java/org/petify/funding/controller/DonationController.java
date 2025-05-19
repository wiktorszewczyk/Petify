package org.petify.funding.controller;

import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.dto.DonationWithPayment;
import org.petify.funding.model.DonationType;
import org.petify.funding.service.DonationService;
import org.petify.funding.service.PaymentService;

import com.stripe.exception.StripeException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/donations")
@RequiredArgsConstructor
public class DonationController {

    private final DonationService donationService;
    private final PaymentService paymentService;

    /**
     * Tworzy darowiznę i od razu PaymentIntent w Stripe.
     * Zwraca darowiznę oraz clientSecret do finalizacji płatności.
     */
    @PostMapping("/create")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public DonationWithPayment donate(
            @RequestBody @Valid DonationRequest req
    ) throws StripeException {
        var donation = donationService.create(req);
        var clientSecret = paymentService.createPaymentIntent(donation.getId());
        return new DonationWithPayment(donation, clientSecret);
    }

    /** Pozostałe operacje CRUD – dostępne tylko dla ADMINów */
    @GetMapping
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public Page<DonationResponse> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) DonationType type
    ) {
        return donationService.getAll(
                PageRequest.of(page, size, Sort.by("donatedAt").descending()),
                type
        );
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public DonationResponse getById(@PathVariable Long id) {
        return donationService.get(id);
    }

    @GetMapping("/shelter/{shelterId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public Page<DonationResponse> getByShelter(
            @PathVariable Long shelterId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return donationService.getForShelter(
                shelterId,
                PageRequest.of(page, size, Sort.by("donatedAt").descending())
        );
    }

    @GetMapping("/pet/{petId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public Page<DonationResponse> getByPet(
            @PathVariable Long petId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return donationService.getForPet(
                petId,
                PageRequest.of(page, size, Sort.by("donatedAt").descending())
        );
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public void delete(@PathVariable Long id) {
        donationService.delete(id);
    }
}
