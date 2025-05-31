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
     * Get available payment options for a donation
     */
    @GetMapping("/options/{donationId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<List<PaymentOptionResponse>> getPaymentOptions(
            @PathVariable Long donationId,
            @RequestParam(required = false) String userCountry) {

        List<PaymentOptionResponse> options = paymentService.getAvailablePaymentOptions(donationId, userCountry);
        return ResponseEntity.ok(options);
    }

    /**
     * Create a new payment
     */
    @PostMapping("/create")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> createPayment(@Valid @RequestBody PaymentRequest request) {
        log.info("Creating payment for donation {}", request.getDonationId());
        PaymentResponse response = paymentService.createPayment(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Get payment status
     */
    @GetMapping("/{paymentId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> getPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.getPaymentById(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Get payment by external ID
     */
    @GetMapping("/external/{externalId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> getPaymentByExternalId(@PathVariable String externalId) {
        PaymentResponse response = paymentService.getPaymentByExternalId(externalId);
        return ResponseEntity.ok(response);
    }

    /**
     * Cancel a payment
     */
    @PostMapping("/{paymentId}/cancel")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> cancelPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.cancelPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Refund a payment (Admin only)
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
     * Get user's payment history
     */
    @GetMapping("/history")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<Page<PaymentResponse>> getPaymentHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {

        Pageable pageable = PageRequest.of(page, size);
        Page<PaymentResponse> payments = paymentService.getUserPaymentHistory(pageable, status);
        return ResponseEntity.ok(payments);
    }

    /**
     * Get payments for a specific donation
     */
    @GetMapping("/donation/{donationId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<PaymentResponse>> getDonationPayments(@PathVariable Long donationId) {
        List<PaymentResponse> payments = paymentService.getPaymentsByDonation(donationId);
        return ResponseEntity.ok(payments);
    }

    /**
     * Stripe webhook endpoint
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
     * PayU webhook endpoint
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
     * Get payment analytics (Admin only)
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
     * Get payment statistics summary (Admin only)
     */
    @GetMapping("/stats")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentStats(
            @RequestParam(required = false, defaultValue = "30") int days) {

        Map<String, Object> stats = analyticsService.getPaymentStatsSummary(days);
        return ResponseEntity.ok(stats);
    }

    /**
     * Retry failed payment
     */
    @PostMapping("/{paymentId}/retry")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> retryPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.retryPayment(paymentId);
        return ResponseEntity.ok(response);
    }

    /**
     * Get payment fee calculation
     */
    @PostMapping("/calculate-fee")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<Map<String, Object>> calculatePaymentFee(
            @RequestBody Map<String, Object> request) {

        java.math.BigDecimal amount = new java.math.BigDecimal(request.get("amount").toString());
        String currency = request.get("currency").toString();
        String provider = request.get("provider").toString();

        Map<String, Object> feeCalculation = paymentService.calculatePaymentFee(
                amount,
                org.petify.funding.model.Currency.valueOf(currency),
                org.petify.funding.model.PaymentProvider.valueOf(provider.toUpperCase())
        );

        return ResponseEntity.ok(feeCalculation);
    }

    /**
     * Get payment methods for a specific provider
     */
    @GetMapping("/methods/{provider}")
    public ResponseEntity<List<String>> getPaymentMethods(@PathVariable String provider) {
        List<String> methods = paymentService.getSupportedPaymentMethods(
                org.petify.funding.model.PaymentProvider.valueOf(provider.toUpperCase())
        );
        return ResponseEntity.ok(methods);
    }

    /**
     * Health check for payment providers
     */
    @GetMapping("/health")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentProvidersHealth() {
        Map<String, Object> health = paymentService.getPaymentProvidersHealth();
        return ResponseEntity.ok(health);
    }
}