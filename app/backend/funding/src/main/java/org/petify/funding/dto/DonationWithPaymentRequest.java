package org.petify.funding.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.PaymentMethod;
import org.petify.funding.model.PaymentProvider;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationWithPaymentRequest {

    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    private Long petId;

    private Integer donorId;

    private String donorUsername;

    @NotNull(message = "Donation type is required")
    private DonationType donationType;

    private String message;
    private Boolean anonymous = false;

    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    private BigDecimal amount;

    private String itemName;
    @DecimalMin(value = "0.01", message = "Unit price must be greater than 0")
    private BigDecimal unitPrice;
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;

    @NotNull(message = "Payment provider is required")
    private PaymentProvider paymentProvider;

    private PaymentMethod paymentMethod;
    private String returnUrl;
    private String cancelUrl;
    private String blikCode;
    private String bankCode;

    // === HELPER METHODS ===
    public DonationRequest toDonationRequest() {
        DonationRequest donationRequest = new DonationRequest();
        donationRequest.setShelterId(shelterId);
        donationRequest.setPetId(petId);
        donationRequest.setDonorId(donorId);
        donationRequest.setDonorUsername(donorUsername);
        donationRequest.setDonationType(donationType);
        donationRequest.setMessage(message);
        donationRequest.setAnonymous(anonymous);
        donationRequest.setAmount(amount);
        donationRequest.setItemName(itemName);
        donationRequest.setUnitPrice(unitPrice);
        donationRequest.setQuantity(quantity);
        return donationRequest;
    }
}
