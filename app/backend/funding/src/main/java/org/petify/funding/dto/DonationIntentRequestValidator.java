package org.petify.funding.dto;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.math.BigDecimal;

class DonationIntentRequestValidator implements ConstraintValidator<DonationIntentRequestValid, DonationIntentRequest> {

    @Override
    public boolean isValid(DonationIntentRequest request, ConstraintValidatorContext context) {
        if (request.getDonationType() == null) {
            return true;
        }

        boolean valid = true;
        context.disableDefaultConstraintViolation();

        switch (request.getDonationType()) {
            case MONEY -> {
                if (request.getAmount() == null || request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Amount is required and must be positive for monetary donations")
                            .addPropertyNode("amount").addConstraintViolation();
                }

                if (request.getItemName() != null || request.getUnitPrice() != null || request.getQuantity() != null) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Material donation fields should not be set for monetary donations")
                            .addConstraintViolation();
                }
            }

            case MATERIAL -> {
                if (request.getAmount() != null) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Amount should not be set for material donations"
                                    + " - it will be calculated automatically")
                            .addPropertyNode("amount").addConstraintViolation();
                }

                if (request.getItemName() == null || request.getItemName().trim().isEmpty()) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Item name is required for material donations")
                            .addPropertyNode("itemName").addConstraintViolation();
                }

                if (request.getUnitPrice() == null || request.getUnitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Unit price is required and must be positive for material donations")
                            .addPropertyNode("unitPrice").addConstraintViolation();
                }

                if (request.getQuantity() == null || request.getQuantity() <= 0) {
                    valid = false;
                    context.buildConstraintViolationWithTemplate("Quantity is required and must be positive for material donations")
                            .addPropertyNode("quantity").addConstraintViolation();
                }
            }
            default -> {
                valid = false;
                context.buildConstraintViolationWithTemplate("Invalid donation type")
                        .addConstraintViolation();
            }
        }

        return valid;
    }
}
