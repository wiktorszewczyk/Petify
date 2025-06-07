package org.petify.funding.dto;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class DonationRequestValidator implements ConstraintValidator<DonationRequestValid, DonationRequest> {
    @Override
    public boolean isValid(DonationRequest dto, ConstraintValidatorContext ctx) {
        if (dto.getDonationType() == null) {
            return true;
        }

        boolean valid = true;
        ctx.disableDefaultConstraintViolation();

        switch (dto.getDonationType()) {
            case MONEY -> {
                if (dto.getAmount() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("Amount is required for monetary donations")
                            .addPropertyNode("amount").addConstraintViolation();
                }
            }
            case MATERIAL -> {
                if (dto.getItemName() == null || dto.getItemName().trim().isEmpty()) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("Item name is required for material donations")
                            .addPropertyNode("itemName").addConstraintViolation();
                }
                if (dto.getUnitPrice() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("Unit price is required for material donations")
                            .addPropertyNode("unitPrice").addConstraintViolation();
                }
                if (dto.getQuantity() == null || dto.getQuantity() < 1) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("Quantity must be at least 1 for material donations")
                            .addPropertyNode("quantity").addConstraintViolation();
                }
            }

            default -> {
            }
        }

        return valid;
    }
}
