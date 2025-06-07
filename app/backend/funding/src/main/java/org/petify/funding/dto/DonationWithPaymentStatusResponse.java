package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DonationWithPaymentStatusResponse {
    private DonationResponse donation;
    private PaymentResponse latestPayment;
    private Boolean isCompleted;
    private String message;

    public String getStatusMessage() {
        if (isCompleted) {
            return "Płatność została zakończona pomyślnie. Dziękujemy za dotację!";
        } else if (latestPayment != null) {
            return switch (latestPayment.getStatus()) {
                case PENDING -> "Płatność oczekuje na realizację";
                case PROCESSING -> "Płatność jest przetwarzana";
                case FAILED -> "Płatność nie powiodła się";
                case CANCELLED -> "Płatność została anulowana";
                default -> "Status płatności: " + latestPayment.getStatus();
            };
        }
        return "Brak informacji o płatności";
    }
}
