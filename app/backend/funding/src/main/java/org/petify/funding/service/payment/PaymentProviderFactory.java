package org.petify.funding.service.payment;

import org.petify.funding.model.PaymentProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class PaymentProviderFactory {

    private final Map<PaymentProvider, PaymentProviderService> providers;

    @Autowired
    public PaymentProviderFactory(StripePaymentService stripeService,
                                  PayUPaymentService payuService) {
        this.providers = Map.of(
                PaymentProvider.STRIPE, stripeService,
                PaymentProvider.PAYU, payuService
        );
    }

    public PaymentProviderService getProvider(PaymentProvider provider) {
        PaymentProviderService service = providers.get(provider);
        if (service == null) {
            throw new IllegalArgumentException("Unsupported payment provider: " + provider);
        }
        return service;
    }

    public Map<PaymentProvider, PaymentProviderService> getAllProviders() {
        return providers;
    }
}
