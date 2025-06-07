package org.petify.funding.config;

import com.stripe.Stripe;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConditionalOnProperty(name = "payment.stripe.enabled", havingValue = "true", matchIfMissing = true)
@EnableConfigurationProperties(PaymentConfiguration.PaymentProperties.class)
@RequiredArgsConstructor
public class StripeConfiguration {

    private final PaymentConfiguration.PaymentProperties paymentProperties;

    @PostConstruct
    public void initializeStripe() {
        Stripe.apiKey = paymentProperties.getStripe().getApiKey();

        Stripe.setMaxNetworkRetries(3);
        Stripe.setConnectTimeout(30 * 1000);
        Stripe.setReadTimeout(80 * 1000);
    }
}
