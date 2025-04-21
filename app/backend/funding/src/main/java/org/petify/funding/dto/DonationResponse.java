package org.petify.funding.dto;

import lombok.*;
import org.petify.funding.model.Donation;
import org.petify.funding.model.MaterialDonation;
import org.petify.funding.model.MonetaryDonation;
import org.petify.funding.model.TaxDonation;

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
    private String donationType;

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
        var resp = new DonationResponse();
        resp.setId(d.getId());
        resp.setShelterId(d.getShelterId());
        resp.setPetId(d.getPetId());
        resp.setDonorUsername(d.getDonorUsername());
        resp.setDonatedAt(d.getDonatedAt());
        resp.setDonationType(
                d instanceof MonetaryDonation ? "MONEY" :
                        d instanceof TaxDonation ? "TAX" :
                                d instanceof MaterialDonation ? "MATERIAL" :
                                        "UNKNOWN"
        );
        switch (d) {
            case MonetaryDonation md -> {
                resp.setAmount(md.getAmount());
                resp.setCurrency(md.getCurrency());
            }
            case TaxDonation td -> {
                resp.setTaxYear(td.getTaxYear());
                resp.setKrsNumber(td.getKrsNumber());
                resp.setTaxAmount(td.getTaxAmount());
            }
            case MaterialDonation mat -> {
                resp.setItemName(mat.getItemName());
                resp.setItemDescription(mat.getItemDescription());
                resp.setQuantity(mat.getQuantity());
                resp.setUnit(mat.getUnit());
            }
            default -> {
            }
        }
        return resp;
    }
}
