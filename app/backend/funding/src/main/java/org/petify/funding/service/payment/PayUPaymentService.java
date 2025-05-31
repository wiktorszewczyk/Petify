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

    @Value("${payment.payu.md5-key}")
    private String md5Key;

    @Override
    @Transactional
    public PaymentResponse createPayment(PaymentRequest request) {
        try {
            log.info("Creating PayU donation payment for donation {}", request.getDonationId());

            Donation donation = donationRepository.findById(request.getDonationId())
                    .orElseThrow(() -> new RuntimeException("Donation not found"));

            String accessToken = getAccessToken();

            Map<String, Object> donationOrderRequest = buildDonationOrderRequest(request, donation);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(accessToken);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(donationOrderRequest, headers);

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
                    .amount(request.getAmount())
                    .currency(request.getCurrency())
                    .paymentMethod(determinePaymentMethod(request))
                    .checkoutUrl(responseJson.get("redirectUri").asText())
                    .metadata(createDonationMetadata(request, donation))
                    .expiresAt(Instant.now().plusSeconds(900))
                    .build();

            Payment savedPayment = paymentRepository.save(payment);

            log.info("PayU donation payment created with ID: {} for donation {}",
                    savedPayment.getId(), donation.getId());
            return PaymentResponse.fromEntity(savedPayment);

        } catch (Exception e) {
            log.error("PayU donation payment creation failed", e);
            throw new RuntimeException("Donation payment creation failed: " + e.getMessage(), e);
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

            log.info("PayU donation payment {} cancelled", payment.getId());
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
            log.info("PayU donation payment {} refunded (amount: {})", payment.getId(), amount);
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
            log.info("Processing PayU donation webhook");

            if (!verifySignature(payload, signature)) {
                throw new RuntimeException("Invalid PayU webhook signature");
            }

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

                            log.info("PayU donation payment {} status updated to {} for donation {}",
                                    payment.getId(), newStatus, payment.getDonation().getId());
                        });
            }

        } catch (Exception e) {
            log.error("Failed to process PayU donation webhook", e);
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
                    .eventType("donation_status_change")
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
        return Set.of(PaymentMethod.CARD, PaymentMethod.BLIK,
                        PaymentMethod.BANK_TRANSFER)
                .contains(method);
    }

    @Override
    public boolean supportsCurrency(Currency currency) {
        return currency == Currency.PLN;
    }

    @Override
    public BigDecimal calculateFee(BigDecimal amount, Currency currency) {
        return amount.multiply(new BigDecimal("0.019"));
    }

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

    private Map<String, Object> buildDonationOrderRequest(PaymentRequest request, Donation donation) {
        Map<String, Object> orderRequest = new HashMap<>();

        orderRequest.put("notifyUrl", apiUrl.replace("secure.snd.payu.com", "your-domain.com") + "/payments/webhook/payu");
        orderRequest.put("customerIp", "127.0.0.1");
        orderRequest.put("merchantPosId", posId);

        String description = buildDonationDescription(donation);
        orderRequest.put("description", description);

        orderRequest.put("currencyCode", request.getCurrency().name());
        orderRequest.put("totalAmount", convertToPayUAmount(request.getAmount()));
        orderRequest.put("extOrderId", "donation_" + request.getDonationId() + "_" + System.currentTimeMillis());

        Map<String, String> buyer = buildBuyerInfo(request, donation);
        if (!buyer.isEmpty()) {
            orderRequest.put("buyer", buyer);
        }

        List<Map<String, Object>> products = buildDonationProducts(donation, request.getAmount());
        orderRequest.put("products", products);

        configureDonationPaymentMethods(orderRequest, request);

        return orderRequest;
    }

    private String buildDonationDescription(Donation donation) {
        StringBuilder desc = new StringBuilder();

        if (donation.getDonationType() == DonationType.MONEY) {
            desc.append("Monetary donation");
        } else {
            MaterialDonation md = (MaterialDonation) donation;
            desc.append("Material donation: ").append(md.getItemName());
        }

        desc.append(" to animal shelter #").append(donation.getShelterId());

        if (donation.getPetId() != null) {
            desc.append(" for pet #").append(donation.getPetId());
        }

        if (donation.getMessage() != null && !donation.getMessage().trim().isEmpty()) {
            desc.append(" - ").append(donation.getMessage().substring(0,
                    Math.min(donation.getMessage().length(), 50)));
        }

        return desc.toString();
    }

    private Map<String, String> buildBuyerInfo(PaymentRequest request, Donation donation) {
        Map<String, String> buyer = new HashMap<>();

        if (donation.getDonorUsername() != null) {
            buyer.put("username", donation.getDonorUsername());
        }

        return buyer;
    }

    private List<Map<String, Object>> buildDonationProducts(Donation donation, BigDecimal amount) {
        List<Map<String, Object>> products = new ArrayList<>();
        Map<String, Object> product = new HashMap<>();

        if (donation.getDonationType() == DonationType.MONEY) {
            product.put("name", "Monetary Donation");
            product.put("unitPrice", convertToPayUAmount(amount));
            product.put("quantity", "1");
        } else {
            MaterialDonation md = (MaterialDonation) donation;
            product.put("name", md.getItemName());
            product.put("unitPrice", convertToPayUAmount(md.getUnitPrice()));
            product.put("quantity", String.valueOf(md.getQuantity()));
        }

        products.add(product);
        return products;
    }

    private void configureDonationPaymentMethods(Map<String, Object> orderRequest, PaymentRequest request) {
        if (request.getPreferredMethod() != null) {
            Map<String, Object> payMethods = new HashMap<>();

            switch (request.getPreferredMethod()) {
                case BLIK:
                    payMethods.put("payMethod", Map.of("type", "BLIK"));
                    if (request.getBlikCode() != null) {
                        payMethods.put("blikCode", request.getBlikCode());
                    }
                    break;
                case BANK_TRANSFER:
                    payMethods.put("payMethod", Map.of("type", "PBL"));
                    if (request.getBankCode() != null) {
                        payMethods.put("bankCode", request.getBankCode());
                    }
                    break;
                case CARD:
                    payMethods.put("payMethod", Map.of("type", "CARD_TOKEN"));
                    break;
            }

            orderRequest.put("payMethods", payMethods);
        }
    }

    private String convertToPayUAmount(BigDecimal amount) {
        return amount.multiply(new BigDecimal("100")).toPlainString();
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
        return PaymentMethod.BLIK;
    }

    private Map<String, String> createDonationMetadata(PaymentRequest request, Donation donation) {
        Map<String, String> metadata = new HashMap<>();
        metadata.put("donationId", String.valueOf(request.getDonationId()));
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

    private boolean verifySignature(String payload, String signature) {
        try {
            String expectedSignature = generateMD5Signature(payload);
            return expectedSignature.equals(signature);
        } catch (Exception e) {
            log.error("Failed to verify PayU signature", e);
            return false;
        }
    }

    private String generateMD5Signature(String payload) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
            String toHash = payload + md5Key;
            byte[] hashBytes = md.digest(toHash.getBytes("UTF-8"));

            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate MD5 signature", e);
        }
    }

    private void updateDonationStatus(Donation donation, DonationStatus newStatus) {
        try {
            donation.setStatus(newStatus);
            if (newStatus == DonationStatus.COMPLETED) {
                donation.setCompletedAt(Instant.now());
                donation.calculateTotalFees();
            }
            donationRepository.save(donation);

            log.info("Updated donation {} status to {}", donation.getId(), newStatus);
        } catch (Exception e) {
            log.error("Failed to update donation status", e);
        }
    }
}