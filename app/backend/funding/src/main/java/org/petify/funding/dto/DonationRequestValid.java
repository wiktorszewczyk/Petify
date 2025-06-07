package org.petify.funding.dto;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Documented
@Constraint(validatedBy = DonationRequestValidator.class)
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface DonationRequestValid {
    String message() default "Invalid donation payload for given donationType";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
