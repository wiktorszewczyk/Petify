package org.petify.funding.dto;

import lombok.*;
import org.petify.funding.model.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * What we send back to the client.
 */
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class DonationResponse {
    private Long id;
    private Long shelterId;
    private Long petId;
    private String donorUsername;
    private Instant donatedAt;
    private DonationType donationType;

    // MONEY
    private BigDecimal amount;
    private String currency;

    // TAX
    private Integer taxYear;
    private String krsNumber;
    private BigDecimal taxAmount;

    // MATERIAL
    private String itemName;
    private String itemDescription;
    private Integer quantity;
    private String unit;

    public static DonationResponse fromEntity(Donation d) {
        DonationResponse resp = new DonationResponse();
        resp.setId(d.getId());
        resp.setShelterId(d.getShelterId());
        resp.setPetId(d.getPetId());
        resp.setDonorUsername(d.getDonorUsername());
        resp.setDonatedAt(d.getDonatedAt());
        resp.setDonationType(d.getDonationType());

        if (d instanceof MonetaryDonation md) {
            resp.setAmount(md.getAmount());
            resp.setCurrency(md.getCurrency());
        } else if (d instanceof TaxDonation td) {
            resp.setTaxYear(td.getTaxYear());
            resp.setKrsNumber(td.getKrsNumber());
            resp.setTaxAmount(td.getTaxAmount());
        } else if (d instanceof MaterialDonation mat) {
            resp.setItemName(mat.getItemName());
            resp.setItemDescription(mat.getItemDescription());
            resp.setQuantity(mat.getQuantity());
            resp.setUnit(mat.getUnit());
        }
        return resp;
    }
}
