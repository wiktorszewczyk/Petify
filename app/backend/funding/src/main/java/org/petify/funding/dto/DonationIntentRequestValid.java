package org.petify.funding.dto;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Documented
@Constraint(validatedBy = DonationIntentRequestValidator.class)
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
public @interface DonationIntentRequestValid {
    String message() default "Invalid donation intent request";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
