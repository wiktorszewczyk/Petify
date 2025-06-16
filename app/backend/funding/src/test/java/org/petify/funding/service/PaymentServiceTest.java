package org.petify.funding.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
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

import static org.assertj.core.api.Assertions.assertThat;
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
        when(providerFactory.getProvider(any())).thenReturn(providerService);
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
}