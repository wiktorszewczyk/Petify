package org.petify.funding.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.mockito.Mockito.lenient;
import org.petify.funding.dto.PaymentFeeCalculation;
import org.petify.funding.model.Currency;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;
import org.petify.funding.service.DonationStatusUpdateService;
import org.petify.funding.service.PaymentService;
import org.petify.funding.service.payment.PaymentProviderFactory;
import org.petify.funding.service.payment.PaymentProviderService;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {

    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private DonationRepository donationRepository;
    @Mock
    private PaymentProviderFactory providerFactory;
    @Mock
    private DonationStatusUpdateService statusUpdateService;
    @Mock
    private PaymentProviderService providerService;

    @InjectMocks
    private PaymentService paymentService;

    @BeforeEach
    void setup() {
        lenient().when(providerFactory.getProvider(any())).thenReturn(providerService);
    }

    @Test
    void calculatePaymentFeeReturnsCorrectValues() {
        BigDecimal amount = new BigDecimal("100.00");
        when(providerService.calculateFee(amount, Currency.PLN)).thenReturn(new BigDecimal("3.00"));

        PaymentFeeCalculation result = paymentService.calculatePaymentFee(amount, PaymentProvider.STRIPE);

        assertThat(result.getGrossAmount()).isEqualByComparingTo("100.00");
        assertThat(result.getFeeAmount()).isEqualByComparingTo("3.00");
        assertThat(result.getNetAmount()).isEqualByComparingTo("97.00");
        BigDecimal expectedPercentage = new BigDecimal("3.00")
                .divide(amount, 4, RoundingMode.HALF_UP)
                .multiply(new BigDecimal("100"));
        assertThat(result.getFeePercentage()).isEqualByComparingTo(expectedPercentage);
        assertThat(result.getProvider()).isEqualTo(PaymentProvider.STRIPE);
        assertThat(result.getCurrency()).isEqualTo(Currency.PLN);
    }


    @Test
    void getAvailablePaymentOptionsForPlUserReturnsBothProviders() {
        when(providerService.calculateFee(new BigDecimal("100"), Currency.PLN)).thenReturn(new BigDecimal("3"));

        var options = paymentService.getAvailablePaymentOptions(new BigDecimal("100"), "PL");

        assertThat(options).hasSize(2);
        assertThat(options.get(0).getProvider()).isEqualTo(PaymentProvider.PAYU);
        assertThat(options.get(1).getProvider()).isEqualTo(PaymentProvider.STRIPE);
    }

    @Test
    void getAvailablePaymentOptionsForNonPlUserReturnsStripeOnly() {
        when(providerService.calculateFee(new BigDecimal("50"), Currency.PLN)).thenReturn(new BigDecimal("1"));

        var options = paymentService.getAvailablePaymentOptions(new BigDecimal("50"), "US");

        assertThat(options).hasSize(1);
        assertThat(options.get(0).getProvider()).isEqualTo(PaymentProvider.STRIPE);
    }

    @Test
    void getSupportedPaymentMethodsDelegatesToProvider() {
        when(providerService.supportsPaymentMethod(org.petify.funding.model.PaymentMethod.CARD)).thenReturn(true);
        when(providerService.supportsPaymentMethod(org.petify.funding.model.PaymentMethod.BLIK)).thenReturn(false);

        var methods = paymentService.getSupportedPaymentMethods(PaymentProvider.PAYU);

        assertThat(methods).contains("CARD").doesNotContain("BLIK");
    }

    @Test
    void getPaymentProvidersHealthReturnsUpStatus() {
        when(providerFactory.getProvider(PaymentProvider.STRIPE)).thenReturn(providerService);
        when(providerFactory.getProvider(PaymentProvider.PAYU)).thenReturn(providerService);
        when(providerService.supportsCurrency(Currency.PLN)).thenReturn(true);
        when(providerService.supportsPaymentMethod(any())).thenReturn(true);

        var health = paymentService.getPaymentProvidersHealth();

        assertThat(((Map<?, ?>) health.get("stripe")).get("status")).isEqualTo("UP");
        assertThat(((Map<?, ?>) health.get("payu")).get("status")).isEqualTo("UP");
    }

    @Test
    void updatePaymentStatusPersistsAndNotifies() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(1L)
                .status(org.petify.funding.model.PaymentStatus.PENDING)
                .build();

        when(paymentRepository.findById(1L)).thenReturn(java.util.Optional.of(payment));
        when(paymentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        paymentService.updatePaymentStatus(1L, org.petify.funding.model.PaymentStatus.SUCCEEDED);

        assertThat(payment.getStatus()).isEqualTo(org.petify.funding.model.PaymentStatus.SUCCEEDED);
        org.mockito.Mockito.verify(statusUpdateService).handlePaymentStatusChange(1L, org.petify.funding.model.PaymentStatus.SUCCEEDED);
    }

    @Test
    void cancelPaymentNotCancellableThrows() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(2L)
                .status(org.petify.funding.model.PaymentStatus.SUCCEEDED)
                .provider(PaymentProvider.STRIPE)
                .externalId("ex")
                .build();
        when(paymentRepository.findById(2L)).thenReturn(java.util.Optional.of(payment));

        assertThatThrownBy(() -> paymentService.cancelPayment(2L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Payment cannot be cancelled");
    }

    @Test
    void refundPaymentAmountExceedingThrows() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(3L)
                .status(org.petify.funding.model.PaymentStatus.SUCCEEDED)
                .provider(PaymentProvider.STRIPE)
                .amount(new BigDecimal("10"))
                .externalId("ex")
                .build();
        when(paymentRepository.findById(3L)).thenReturn(java.util.Optional.of(payment));

        assertThatThrownBy(() -> paymentService.refundPayment(3L, new BigDecimal("20")))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Refund amount cannot exceed");
    }
}