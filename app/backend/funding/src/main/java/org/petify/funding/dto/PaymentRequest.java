package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Builder;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentRequest {

    @NotNull(message = "Donation ID is required")
    private Long donationId;

    @NotNull(message = "Payment provider is required")
    private PaymentProvider preferredProvider;

    private PaymentMethod preferredMethod;

    @NotNull(message = "Currency is required")
    private Currency currency;

    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    @Email(message = "Invalid email format")
    private String customerEmail;

    private String customerName;

    private String returnUrl;

    private String cancelUrl;

    private String description;

    // For BLIK payments
    @Pattern(regexp = "\\d{6}", message = "BLIK code must be 6 digits")
    private String blikCode;

    // For bank transfers
    private String bankCode;
}
