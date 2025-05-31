package org.petify.funding.controller;

import org.petify.funding.dto.*;
import org.petify.funding.service.PaymentService;
import org.petify.funding.service.PaymentAnalyticsService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
@Slf4j
public class PaymentController {

    private final PaymentService paymentService;
    private final PaymentAnalyticsService analyticsService;

    /**
     * Tworzy nową płatność dla istniejącej dotacji
     */
    @PostMapping
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> createPayment(@Valid @RequestBody PaymentRequest request) {
        log.info("Creating payment for donation {}", request.getDonationId());
        PaymentResponse response = paymentService.createPayment(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Pobiera status płatności
     */
    @GetMapping("/{paymentId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> getPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.getPaymentById(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Pobiera płatność po external ID (dla webhook'ów)
     */
    @GetMapping("/external/{externalId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> getPaymentByExternalId(@PathVariable String externalId) {
        PaymentResponse response = paymentService.getPaymentByExternalId(externalId);
        return ResponseEntity.ok(response);
    }

    /**
     * Anuluje płatność
     */
    @PostMapping("/{paymentId}/cancel")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> cancelPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.cancelPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Zwraca płatność (tylko admin)
     */
    @PostMapping("/{paymentId}/refund")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<PaymentResponse> refundPayment(
            @PathVariable Long paymentId,
            @RequestParam(required = false) java.math.BigDecimal amount) {

        PaymentResponse response = paymentService.refundPayment(paymentId, amount);
        return ResponseEntity.ok(response);
    }

    /**
     * Historia płatności użytkownika
     */
    @GetMapping("/my-history")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<Page<PaymentResponse>> getMyPaymentHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {

        Pageable pageable = PageRequest.of(page, size);
        Page<PaymentResponse> payments = paymentService.getUserPaymentHistory(pageable, status);
        return ResponseEntity.ok(payments);
    }

    /**
     * Pobiera płatności dla konkretnej dotacji (admin)
     */
    @GetMapping("/donation/{donationId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<PaymentResponse>> getDonationPayments(@PathVariable Long donationId) {
        List<PaymentResponse> payments = paymentService.getPaymentsByDonation(donationId);
        return ResponseEntity.ok(payments);
    }

    /**
     * Ponawia nieudaną płatność
     */
    @PostMapping("/{paymentId}/retry")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> retryPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.retryPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Oblicza opłaty za płatność
     */
    @PostMapping("/calculate-fee")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentService.PaymentFeeCalculation> calculatePaymentFee(
            @RequestBody CalculateFeesRequest request) {

        PaymentService.PaymentFeeCalculation calculation = paymentService.calculatePaymentFee(
                request.getAmount(),
                request.getProvider() != null ? request.getProvider() : org.petify.funding.model.PaymentProvider.PAYU
        );

        return ResponseEntity.ok(calculation);
    }

    /**
     * Sprawdza status providerów płatności
     */
    @GetMapping("/providers/health")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentProvidersHealth() {
        Map<String, Object> health = paymentService.getPaymentProvidersHealth();
        return ResponseEntity.ok(health);
    }

    /**
     * Webhook Stripe
     */
    @PostMapping("/webhook/stripe")
    public ResponseEntity<Void> handleStripeWebhook(
            @RequestBody String payload,
            @RequestHeader("Stripe-Signature") String signature) {

        try {
            paymentService.handleStripeWebhook(payload, signature);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to process Stripe webhook", e);
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Webhook PayU
     */
    @PostMapping("/webhook/payu")
    public ResponseEntity<Void> handlePayUWebhook(
            @RequestBody String payload,
            @RequestHeader(value = "OpenPayu-Signature", required = false) String signature) {

        try {
            paymentService.handlePayUWebhook(payload, signature);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to process PayU webhook", e);
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Pobiera analityki płatności
     */
    @GetMapping("/analytics")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<PaymentAnalyticsResponse>> getPaymentAnalytics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String provider) {

        List<PaymentAnalyticsResponse> analytics = analyticsService.getAnalytics(startDate, endDate, provider);
        return ResponseEntity.ok(analytics);
    }

    /**
     * Pobiera podsumowanie statystyk płatności
     */
    @GetMapping("/stats")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentStats(
            @RequestParam(required = false, defaultValue = "30") int days) {

        Map<String, Object> stats = analyticsService.getPaymentStatsSummary(days);
        return ResponseEntity.ok(stats);
    }

    /**
     * Pobiera obsługiwane metody płatności dla providera
     */
    @GetMapping("/methods/{provider}")
    public ResponseEntity<List<String>> getPaymentMethods(@PathVariable String provider) {
        try {
            org.petify.funding.model.PaymentProvider paymentProvider =
                    org.petify.funding.model.PaymentProvider.valueOf(provider.toUpperCase());

            List<String> methods = java.util.Arrays.stream(org.petify.funding.model.PaymentMethod.values())
                    .map(Enum::name)
                    .collect(java.util.stream.Collectors.toList());

            return ResponseEntity.ok(methods);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
