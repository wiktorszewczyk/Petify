package org.petify.funding.controller;

import org.petify.funding.service.PaymentService;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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
     */
    @PostMapping("/create-intent")
    @ResponseStatus(HttpStatus.CREATED)
    public String createIntent(@RequestParam @NotNull Long donationId) throws StripeException {
        return paymentService.createPaymentIntent(donationId);
    }

    /**
     * Webhook endpoint Stripe’a – przyjmuje zdarzenia POST.
     */
    @PostMapping("/webhook")
    @ResponseStatus(HttpStatus.OK)
    public void webhook(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String sigHeader
    ) throws SignatureVerificationException {
        paymentService.handleWebhook(payload, sigHeader);
    }
}
