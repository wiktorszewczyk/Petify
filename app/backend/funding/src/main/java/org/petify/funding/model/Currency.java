package org.petify.funding.model;

public enum Currency {
    PLN("zł", true),
    EUR("€", false),
    USD("$", false),
    GBP("£", false);

    private final String symbol;
    private final boolean isDefault;

    Currency(String symbol, boolean isDefault) {
        this.symbol = symbol;
        this.isDefault = isDefault;
    }

    public String getSymbol() {
        return symbol;
    }

    public boolean isDefault() {
        return isDefault;
    }

    public static Currency getDefault() {
        return PLN;
    }
}
