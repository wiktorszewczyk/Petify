package org.petify.funding.dto;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = DonationRequestValidator.class)
@Documented
public @interface DonationRequestValid {
    String message() default "Invalid donation payload for given donationType";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}