package org.petify.funding.service.payment;

import org.petify.funding.dto.PaymentRequest;
import org.petify.funding.dto.PaymentResponse;
import org.petify.funding.dto.WebhookEventDto;

public interface PaymentProviderService {

    PaymentResponse createPayment(PaymentRequest request);

    PaymentResponse getPaymentStatus(String externalId);

    PaymentResponse cancelPayment(String externalId);

    PaymentResponse refundPayment(String externalId, java.math.BigDecimal amount);

    void handleWebhook(String payload, String signature);

    WebhookEventDto parseWebhookEvent(String payload, String signature);

    boolean supportsPaymentMethod(org.petify.funding.model.PaymentMethod method);

    boolean supportsCurrency(org.petify.funding.model.Currency currency);

    java.math.BigDecimal calculateFee(java.math.BigDecimal amount,
                                      org.petify.funding.model.Currency currency);
}