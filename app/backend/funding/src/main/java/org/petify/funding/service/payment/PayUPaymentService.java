package org.petify.funding.service.payment;

import org.petify.funding.dto.PaymentRequest;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.dto.WebhookEventDto;
import org.petify.funding.model.*;
import org.petify.funding.model.Currency;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class PayUPaymentService implements PaymentProviderService {

    private final PaymentRepository paymentRepository;
    private final DonationRepository donationRepository;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${payment.payu.client-id}")
    private String clientId;

    @Value("${payment.payu.client-secret}")
    private String clientSecret;

    @Value("${payment.payu.api-url}")
    private String apiUrl;

    @Value("${payment.payu.pos-id}")
    private String posId;

    @Value("${app.webhook.base-url:http://localhost:8222}")
    private String webhookBaseUrl;

    @Override
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        try {
            log.info("Creating PayU payment for donation {}", request.getDonationId());

            Donation donation = donationRepository.findById(request.getDonationId())
                    .orElseThrow(() -> new RuntimeException("Donation not found"));

            String accessToken = getAccessToken();
            Map<String, Object> orderRequest = buildOrderRequest(donation, request);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(accessToken);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(orderRequest, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl + "/api/v2_1/orders",
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            JsonNode responseJson = objectMapper.readTree(response.getBody());

            if (responseJson.has("status") &&
                    responseJson.get("status").has("statusCode") &&
                    !"SUCCESS".equals(responseJson.get("status").get("statusCode").asText())) {
                throw new RuntimeException("PayU order creation failed: " +
                        responseJson.get("status").get("statusDesc").asText());
            }

            Payment payment = Payment.builder()
                    .donation(donation)
                    .provider(PaymentProvider.PAYU)
                    .externalId(responseJson.get("orderId").asText())
                    .status(PaymentStatus.PENDING)
                    .amount(donation.getAmount())
                    .currency(Currency.PLN)
                    .paymentMethod(determinePaymentMethod(request))
                    .checkoutUrl(responseJson.get("redirectUri").asText())
                    .metadata(createMetadata(donation))
                    .expiresAt(Instant.now().plusSeconds(900))
                    .build();

            Payment savedPayment = paymentRepository.save(payment);

            log.info("PayU payment created with ID: {} for donation {}",
                    savedPayment.getId(), donation.getId());
            return PaymentResponse.fromEntity(savedPayment);

        } catch (Exception e) {
            log.error("PayU payment creation failed", e);
            throw new RuntimeException("Payment creation failed: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse getPaymentStatus(String externalId) {
        try {
            String accessToken = getAccessToken();

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl + "/api/v2_1/orders/" + externalId,
                    HttpMethod.GET,
                    entity,
                    String.class
            );

            JsonNode responseJson = objectMapper.readTree(response.getBody());
            JsonNode orderJson = responseJson.get("orders").get(0);

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            PaymentStatus oldStatus = payment.getStatus();
            PaymentStatus newStatus = mapPayUStatus(orderJson.get("status").asText());

            payment.setStatus(newStatus);

            if (newStatus == PaymentStatus.SUCCEEDED && oldStatus != PaymentStatus.SUCCEEDED) {
                updateDonationStatus(payment.getDonation(), DonationStatus.COMPLETED);
            }

            Payment savedPayment = paymentRepository.save(payment);
            return PaymentResponse.fromEntity(savedPayment);

        } catch (Exception e) {
            log.error("Failed to get PayU payment status", e);
            throw new RuntimeException("Failed to get payment status: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse cancelPayment(String externalId) {
        try {
            String accessToken = getAccessToken();

            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl + "/api/v2_1/orders/" + externalId,
                    HttpMethod.DELETE,
                    entity,
                    String.class
            );

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            payment.setStatus(PaymentStatus.CANCELLED);
            Payment savedPayment = paymentRepository.save(payment);

            log.info("PayU payment {} cancelled", payment.getId());
            return PaymentResponse.fromEntity(savedPayment);

        } catch (Exception e) {
            log.error("Failed to cancel PayU payment", e);
            throw new RuntimeException("Failed to cancel payment: " + e.getMessage(), e);
        }
    }

    @Override
    public PaymentResponse refundPayment(String externalId, BigDecimal amount) {
        try {
            String accessToken = getAccessToken();

            Map<String, Object> refundRequest = new HashMap<>();
            refundRequest.put("refund", Map.of(
                    "description", "Refund for donation",
                    "amount", convertToPayUAmount(amount)
            ));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(accessToken);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(refundRequest, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl + "/api/v2_1/orders/" + externalId + "/refunds",
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            Payment payment = paymentRepository.findByExternalId(externalId)
                    .orElseThrow(() -> new RuntimeException("Payment not found"));

            if (amount.compareTo(payment.getAmount()) == 0) {
                payment.setStatus(PaymentStatus.REFUNDED);
                updateDonationStatus(payment.getDonation(), DonationStatus.FAILED);
            } else {
                payment.setStatus(PaymentStatus.PARTIALLY_REFUNDED);
            }

            Payment savedPayment = paymentRepository.save(payment);
            log.info("PayU payment {} refunded (amount: {})", payment.getId(), amount);
            return PaymentResponse.fromEntity(savedPayment);

        } catch (Exception e) {
            log.error("Failed to refund PayU payment", e);
            throw new RuntimeException("Failed to refund payment: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional
    public void handleWebhook(String payload, String signature) {
        try {
            log.info("Processing PayU webhook");

            JsonNode webhookData = objectMapper.readTree(payload);
            JsonNode orderData = webhookData.get("order");

            if (orderData != null) {
                String orderId = orderData.get("orderId").asText();
                String status = orderData.get("status").asText();

                paymentRepository.findByExternalId(orderId)
                        .ifPresent(payment -> {
                            PaymentStatus oldStatus = payment.getStatus();
                            PaymentStatus newStatus = mapPayUStatus(status);
                            payment.setStatus(newStatus);
                            paymentRepository.save(payment);

                            if (newStatus == PaymentStatus.SUCCEEDED && oldStatus != PaymentStatus.SUCCEEDED) {
                                updateDonationStatus(payment.getDonation(), DonationStatus.COMPLETED);
                            } else if (newStatus == PaymentStatus.FAILED && oldStatus != PaymentStatus.FAILED) {
                                updateDonationStatus(payment.getDonation(), DonationStatus.FAILED);
                            }

                            log.info("PayU payment {} status updated to {} for donation {}",
                                    payment.getId(), newStatus, payment.getDonation().getId());
                        });
            }

        } catch (Exception e) {
            log.error("Failed to process PayU webhook", e);
            throw new RuntimeException("Failed to process webhook", e);
        }
    }

    @Override
    public WebhookEventDto parseWebhookEvent(String payload, String signature) {
        try {
            JsonNode webhookData = objectMapper.readTree(payload);
            JsonNode orderData = webhookData.get("order");

            return WebhookEventDto.builder()
                    .eventId(UUID.randomUUID().toString())
                    .eventType("payment_status_change")
                    .provider(PaymentProvider.PAYU.getValue())
                    .externalPaymentId(orderData.get("orderId").asText())
                    .receivedAt(Instant.now())
                    .processed(false)
                    .eventData(objectMapper.convertValue(webhookData, Map.class))
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("Failed to parse webhook event", e);
        }
    }

    @Override
    public boolean supportsPaymentMethod(PaymentMethod method) {
        return Set.of(
                PaymentMethod.CARD,
                PaymentMethod.BLIK,
                PaymentMethod.BANK_TRANSFER
        ).contains(method);
    }

    @Override
    public boolean supportsCurrency(Currency currency) {
        return currency == Currency.PLN;
    }

    @Override
    public BigDecimal calculateFee(BigDecimal amount, Currency currency) {
        return amount.multiply(new BigDecimal("0.019")); // 1.9%
    }

    // === PRIVATE HELPER METHODS ===

    private String getAccessToken() {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            String body = "grant_type=client_credentials" +
                    "&client_id=" + clientId +
                    "&client_secret=" + clientSecret;

            HttpEntity<String> entity = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    apiUrl + "/pl/standard/user/oauth/authorize",
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            JsonNode responseJson = objectMapper.readTree(response.getBody());
            return responseJson.get("access_token").asText();

        } catch (Exception e) {
            log.error("Failed to get PayU access token", e);
            throw new RuntimeException("Failed to authenticate with PayU", e);
        }
    }

    private Map<String, Object> buildOrderRequest(Donation donation, PaymentRequest request) {
        Map<String, Object> orderRequest = new HashMap<>();

        orderRequest.put("notifyUrl", webhookBaseUrl + "/payments/webhook/payu");
        orderRequest.put("customerIp", "127.0.0.1");
        orderRequest.put("merchantPosId", posId);
        orderRequest.put("description", buildDescription(donation));
        orderRequest.put("currencyCode", "PLN");
        orderRequest.put("totalAmount", convertToPayUAmount(donation.getAmount()));

        // Krótki external order ID
        String extOrderId = "d" + donation.getId() + "_" + (System.nanoTime() % 100000);
        orderRequest.put("extOrderId", extOrderId);

        // Buyer info
        Map<String, String> buyer = buildBuyerInfo(donation);
        if (!buyer.isEmpty()) {
            orderRequest.put("buyer", buyer);
        }

        // Products
        orderRequest.put("products", buildProducts(donation));

        // Payment methods - tylko jeśli określono
        configurePaymentMethods(orderRequest, request);

        // Return URL
        if (request.getReturnUrl() != null && !request.getReturnUrl().trim().isEmpty()) {
            orderRequest.put("continueUrl", request.getReturnUrl());
        }

        return orderRequest;
    }

    private String buildDescription(Donation donation) {
        StringBuilder desc = new StringBuilder();

        if (donation instanceof MaterialDonation md) {
            String itemName = md.getItemName();
            if (itemName != null && !itemName.trim().isEmpty()) {
                desc.append("Dotacja rzeczowa: ").append(itemName);
            } else {
                desc.append("Dotacja rzeczowa");
            }
        } else {
            desc.append("Dotacja pieniężna");
        }

        desc.append(" dla schroniska #").append(donation.getShelterId());

        if (donation.getPetId() != null) {
            desc.append(" dla zwierzęcia #").append(donation.getPetId());
        }

        return desc.toString();
    }

    private Map<String, String> buildBuyerInfo(Donation donation) {
        Map<String, String> buyer = new HashMap<>();

        if (donation.getDonorUsername() != null && !donation.getDonorUsername().trim().isEmpty()) {
            if (donation.isDonorUsernameEmail()) {
                buyer.put("email", donation.getDonorUsername());
                buyer.put("firstName", "Darczyńca");
                buyer.put("lastName", "Anonimowy");
            } else {
                buyer.put("firstName", donation.getDonorUsername());
                buyer.put("lastName", "");
            }
        }

        return buyer;
    }

    private List<Map<String, Object>> buildProducts(Donation donation) {
        List<Map<String, Object>> products = new ArrayList<>();
        Map<String, Object> product = new HashMap<>();

        if (donation instanceof MaterialDonation md) {
            String itemName = md.getItemName();
            if (itemName == null || itemName.trim().isEmpty()) {
                itemName = "Dotacja rzeczowa";
            }

            BigDecimal unitPrice = md.getUnitPrice();
            Integer quantity = md.getQuantity();

            if (unitPrice == null) {
                throw new IllegalArgumentException("Material donation unit price cannot be null");
            }

            if (quantity == null || quantity <= 0) {
                quantity = 1;
            }

            product.put("name", itemName);
            product.put("unitPrice", convertToPayUAmount(unitPrice));
            product.put("quantity", quantity);

        } else {
            product.put("name", "Dotacja pieniężna dla schroniska");
            product.put("unitPrice", convertToPayUAmount(donation.getAmount()));
            product.put("quantity", 1);
        }

        products.add(product);
        return products;
    }

    private void configurePaymentMethods(Map<String, Object> orderRequest, PaymentRequest request) {
        // Dla karty - nie określaj payMethods, PayU pokaże formularz wyboru
        if (request.getPreferredMethod() == null || request.getPreferredMethod() == PaymentMethod.CARD) {
            return;
        }

        Map<String, Object> payMethods = new HashMap<>();

        switch (request.getPreferredMethod()) {
            case BLIK:
                Map<String, Object> blikMethod = new HashMap<>();
                blikMethod.put("type", "PBL");
                blikMethod.put("value", "blik");
                payMethods.put("payMethod", blikMethod);

                if (request.getBlikCode() != null && !request.getBlikCode().trim().isEmpty()) {
                    payMethods.put("authorizationCode", request.getBlikCode());
                }
                break;

            case BANK_TRANSFER:
                Map<String, Object> bankMethod = new HashMap<>();
                bankMethod.put("type", "PBL");
                bankMethod.put("value", request.getBankCode() != null ?
                        request.getBankCode() : "t"); // "t" = ogólny transfer
                payMethods.put("payMethod", bankMethod);
                break;

            default:
                // Dla innych metod - nie określaj, PayU pokaże opcje
                return;
        }

        if (!payMethods.isEmpty()) {
            orderRequest.put("payMethods", payMethods);
        }
    }

    private String convertToPayUAmount(BigDecimal amount) {
        if (amount == null) {
            throw new IllegalArgumentException("Amount cannot be null");
        }

        BigDecimal amountInGrosze = amount.multiply(new BigDecimal("100"));

        if (amountInGrosze.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }

        if (amountInGrosze.compareTo(new BigDecimal("999999999")) > 0) {
            throw new IllegalArgumentException("Amount too large for PayU");
        }

        return amountInGrosze.setScale(0, RoundingMode.HALF_UP).toPlainString();
    }

    private PaymentStatus mapPayUStatus(String payuStatus) {
        return switch (payuStatus.toLowerCase()) {
            case "new", "pending" -> PaymentStatus.PENDING;
            case "waiting_for_confirmation" -> PaymentStatus.PROCESSING;
            case "completed" -> PaymentStatus.SUCCEEDED;
            case "canceled" -> PaymentStatus.CANCELLED;
            case "rejected" -> PaymentStatus.FAILED;
            default -> PaymentStatus.PENDING;
        };
    }

    private PaymentMethod determinePaymentMethod(PaymentRequest request) {
        if (request.getPreferredMethod() != null) {
            return request.getPreferredMethod();
        }
        return PaymentMethod.CARD; // Domyślnie karta
    }

    private Map<String, String> createMetadata(Donation donation) {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("donationId", String.valueOf(donation.getId()));
        metadata.put("provider", PaymentProvider.PAYU.getValue());
        metadata.put("donationType", donation.getDonationType().name());
        metadata.put("shelterId", String.valueOf(donation.getShelterId()));

        if (donation.getPetId() != null) {
            metadata.put("petId", String.valueOf(donation.getPetId()));
        }
        if (donation.getDonorUsername() != null) {
            metadata.put("donorUsername", donation.getDonorUsername());
        }

        return metadata;
    }

    private void updateDonationStatus(Donation donation, DonationStatus newStatus) {
        try {
            donation.setStatus(newStatus);
            if (newStatus == DonationStatus.COMPLETED) {
                donation.setCompletedAt(Instant.now());
            }
            donationRepository.save(donation);

            log.info("Updated donation {} status to {}", donation.getId(), newStatus);
        } catch (Exception e) {
            log.error("Failed to update donation status", e);
        }
    }
}
