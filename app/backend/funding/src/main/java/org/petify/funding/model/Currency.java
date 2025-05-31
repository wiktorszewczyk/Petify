package org.petify.funding.model;

/**
 * Enum reprezentujący obsługiwane waluty
 * Na razie skupiamy się na PLN, ale struktura pozwala na rozszerzenie
 */
public enum Currency {
    PLN("zł", true, "Polski złoty"),
    EUR("€", false, "Euro"),
    USD("$", false, "US Dollar"),
    GBP("£", false, "British Pound");

    private final String symbol;
    private final boolean isDefault;
    private final String displayName;

    Currency(String symbol, boolean isDefault, String displayName) {
        this.symbol = symbol;
        this.isDefault = isDefault;
        this.displayName = displayName;
    }

    public String getSymbol() {
        return symbol;
    }

    public boolean isDefault() {
        return isDefault;
    }

    public String getDisplayName() {
        return displayName;
    }

    public static Currency getDefault() {
        return PLN;
    }

    public boolean isSupportedByPayU() {
        return this == PLN;
    }

    public boolean isSupportedByStripe() {
        return this == USD || this == EUR || this == GBP || this == PLN;
    }

    public String formatAmount(java.math.BigDecimal amount) {
        return switch (this) {
            case PLN -> amount.toPlainString() + " " + symbol;
            case EUR, USD, GBP -> symbol + amount.toPlainString();
        };
    }
}
