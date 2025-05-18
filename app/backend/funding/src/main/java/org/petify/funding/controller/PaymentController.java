package org.petify.funding.controller;

import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.petify.funding.service.PaymentService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

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
