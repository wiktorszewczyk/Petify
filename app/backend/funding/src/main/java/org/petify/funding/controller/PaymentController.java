package org.petify.funding.controller;

import org.petify.funding.service.PaymentService;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import jakarta.annotation.security.PermitAll;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    /**
     * Utworzenie Stripe PaymentIntent, zwraca clientSecret.
     * Dostępne dla każdego zalogowanego użytkownika (ROLE_USER lub innej uprawnionej roli).
     */
    @PostMapping("/create-intent")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public String createIntent(@RequestParam @NotNull Long donationId)
            throws StripeException {
        return paymentService.createPaymentIntent(donationId);
    }

    /**
     * Webhook endpoint Stripe’a – przyjmuje zdarzenia POST.
     * Publiczny, Stripe weryfikowany jest sygnaturą nagłówka.
     */
    @PostMapping("/webhook")
    @ResponseStatus(HttpStatus.OK)
    @PermitAll
    public void webhook(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String sigHeader
    ) throws SignatureVerificationException {
        paymentService.handleWebhook(payload, sigHeader);
    }
}
