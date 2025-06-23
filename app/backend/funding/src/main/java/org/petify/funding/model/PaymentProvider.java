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
}
