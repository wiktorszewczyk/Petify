package org.petify.funding.model;

public enum Currency {
    PLN(true),
    EUR(false),
    USD(false),
    GBP(false);

    private final boolean isDefault;

    Currency(boolean isDefault) {
        this.isDefault = isDefault;
    }

    public boolean isDefault() {
        return isDefault;
    }

    public static Currency getDefault() {
        return PLN;
    }
}
