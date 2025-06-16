package org.petify.funding.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.service.payment.PayUPaymentService;
import org.petify.funding.service.payment.PaymentProviderFactory;
import org.petify.funding.service.payment.StripePaymentService;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@ExtendWith(MockitoExtension.class)
class PaymentProviderFactoryTest {

    @Mock
    private StripePaymentService stripePaymentService;
    @Mock
    private PayUPaymentService payuPaymentService;

    private PaymentProviderFactory factory;

    @BeforeEach
    void setUp() {
        factory = new PaymentProviderFactory(stripePaymentService, payuPaymentService);
    }

    @Test
    void returnsProperService() {
        assertThat(factory.getProvider(PaymentProvider.STRIPE)).isEqualTo(stripePaymentService);
        assertThat(factory.getProvider(PaymentProvider.PAYU)).isEqualTo(payuPaymentService);
    }

    @Test
    void unsupportedProviderThrows() {
        assertThatThrownBy(() -> factory.getProvider(null))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    void getAllProvidersContainsBothEntries() {
        var providers = factory.getAllProviders();
        assertThat(providers).containsKeys(PaymentProvider.STRIPE, PaymentProvider.PAYU);
    }

    @Test
    void getProviderReturnsSameInstance() {
        var stripe = factory.getProvider(PaymentProvider.STRIPE);
        assertThat(factory.getProvider(PaymentProvider.STRIPE)).isSameAs(stripe);
    }
}