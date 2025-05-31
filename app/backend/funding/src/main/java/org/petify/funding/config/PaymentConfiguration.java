package org.petify.funding.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.client.RestTemplate;

import lombok.Data;

@Configuration
@EnableScheduling
public class PaymentConfiguration {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @ConfigurationProperties(prefix = "payment")
    @Data
    public static class PaymentProperties {
        private Stripe stripe = new Stripe();
        private PayU payu = new PayU();
        private Analytics analytics = new Analytics();

        @Data
        public static class Stripe {
            private String apiKey;
            private String publishableKey;
            private String webhookSecret;
            private boolean enabled = true;
            private String apiVersion = "2023-10-16";
        }

        @Data
        public static class PayU {
            private String clientId;
            private String clientSecret;
            private String posId;
            private String md5Key;
            private String apiUrl = "https://secure.snd.payu.com";
            private boolean enabled = true;
            private boolean sandboxMode = true;
        }

        @Data
        public static class Analytics {
            private boolean enabled = true;
            private int retentionDays = 365;
            private String aggregationSchedule = "0 0 1 * * ?"; // 1 AM daily
        }
    }
}