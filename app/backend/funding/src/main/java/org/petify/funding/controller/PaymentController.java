package org.petify.funding.controller;

import org.petify.funding.dto.CalculateFeesRequest;
import org.petify.funding.dto.PaymentAnalyticsResponse;
import org.petify.funding.dto.PaymentFeeCalculation;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.service.PaymentAnalyticsService;
import org.petify.funding.service.PaymentService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
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

    @GetMapping("/{paymentId}")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentResponse> getPayment(@PathVariable Long paymentId) {
        PaymentResponse response = paymentService.getPaymentById(paymentId);
        return ResponseEntity.ok(response);
    }

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

    @PostMapping("/calculate-fee")
    @PreAuthorize("hasAuthority('ROLE_USER')")
    public ResponseEntity<PaymentFeeCalculation> calculatePaymentFee(
            @RequestBody CalculateFeesRequest request) {

        PaymentFeeCalculation calculation = paymentService.calculatePaymentFee(
                request.getAmount(),
                request.getProvider() != null ? request.getProvider() : PaymentProvider.PAYU
        );

        return ResponseEntity.ok(calculation);
    }

    @GetMapping("/methods/{provider}")
    public ResponseEntity<List<String>> getPaymentMethods(@PathVariable String provider) {
        try {
            PaymentProvider paymentProvider = PaymentProvider.valueOf(provider.toUpperCase());

            List<String> methods = paymentService.getSupportedPaymentMethods(paymentProvider);
            return ResponseEntity.ok(methods);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

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

    @GetMapping("/donation/{donationId}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<PaymentResponse>> getDonationPayments(@PathVariable Long donationId) {
        List<PaymentResponse> payments = paymentService.getPaymentsByDonation(donationId);
        return ResponseEntity.ok(payments);
    }

    @PostMapping("/{paymentId}/refund")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<PaymentResponse> refundPayment(
            @PathVariable Long paymentId,
            @RequestParam(required = false) BigDecimal amount) {

        PaymentResponse response = paymentService.refundPayment(paymentId, amount);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/providers/health")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentProvidersHealth() {
        Map<String, Object> health = paymentService.getPaymentProvidersHealth();
        return ResponseEntity.ok(health);
    }

    @GetMapping("/analytics")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<List<PaymentAnalyticsResponse>> getPaymentAnalytics(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String provider) {

        List<PaymentAnalyticsResponse> analytics = analyticsService.getAnalytics(startDate, endDate, provider);
        return ResponseEntity.ok(analytics);
    }

    @GetMapping("/stats")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<Map<String, Object>> getPaymentStats(
            @RequestParam(required = false, defaultValue = "30") int days) {

        Map<String, Object> stats = analyticsService.getPaymentStatsSummary(days);
        return ResponseEntity.ok(stats);
    }
}
