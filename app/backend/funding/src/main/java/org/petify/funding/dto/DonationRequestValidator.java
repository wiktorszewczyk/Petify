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
                    ctx.buildConstraintViolationWithTemplate("amount is required for MONEY")
                            .addPropertyNode("amount").addConstraintViolation();
                }
                if (dto.getCurrency() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("currency is required for MONEY")
                            .addPropertyNode("currency").addConstraintViolation();
                }
                if (dto.getPetId() != null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("petId must be null for MONEY")
                            .addPropertyNode("petId").addConstraintViolation();
                }
            }
            case MATERIAL -> {
                if (dto.getItemName() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("itemName is required for MATERIAL")
                            .addPropertyNode("itemName").addConstraintViolation();
                }
                if (dto.getUnitPrice() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("unitPrice is required for MATERIAL")
                            .addPropertyNode("unitPrice").addConstraintViolation();
                }
                if (dto.getQuantity() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("quantity is required for MATERIAL")
                            .addPropertyNode("quantity").addConstraintViolation();
                }
                if (dto.getCurrency() == null) {
                    valid = false;
                    ctx.buildConstraintViolationWithTemplate("currency is required for MATERIAL")
                            .addPropertyNode("currency").addConstraintViolation();
                }
            }
        }

        return valid;
    }
}
