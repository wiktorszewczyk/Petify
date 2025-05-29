package org.petify.funding.model;

public enum PaymentProvider {
    STRIPE("stripe"),
    PAYU("payu");

    private final String value;

    PaymentProvider(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    public static PaymentProvider fromString(String provider) {
        for (PaymentProvider p : PaymentProvider.values()) {
            if (p.value.equalsIgnoreCase(provider)) {
                return p;
            }
        }
        throw new IllegalArgumentException("Unknown payment provider: " + provider);
    }
}