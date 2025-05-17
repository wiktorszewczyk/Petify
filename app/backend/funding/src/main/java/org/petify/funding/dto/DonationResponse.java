package org.petify.funding.dto;

import lombok.*;
import org.petify.funding.model.*;
import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationResponse {

    private Long id;
    private Long shelterId;
    private Long petId;
    private String donorUsername;
    private Instant donatedAt;
    private DonationType donationType;

    // monetary
    private BigDecimal amount;
    private String currency;

    // material
    private String itemName;
    private BigDecimal unitPrice;
    private Integer quantity;

    public static DonationResponse fromEntity(Donation d) {
        DonationResponse r = new DonationResponse();
        r.setId(d.getId());
        r.setShelterId(d.getShelterId());
        r.setPetId(d.getPetId());
        r.setDonorUsername(d.getDonorUsername());
        r.setDonatedAt(d.getDonatedAt());
        r.setDonationType(d.getDonationType());

        if (d instanceof MonetaryDonation m) {
            r.setAmount(m.getAmount());
            r.setCurrency(m.getCurrency());
        } else if (d instanceof MaterialDonation m) {
            r.setItemName(m.getItemName());
            r.setUnitPrice(m.getUnitPrice());
            r.setQuantity(m.getQuantity());
            r.setCurrency(m.getCurrency());
            r.setAmount(m.getAmount());
        }
        return r;
    }
}
