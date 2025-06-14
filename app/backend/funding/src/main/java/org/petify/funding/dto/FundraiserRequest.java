package org.petify.funding.dto;

import org.petify.funding.model.Currency;
import org.petify.funding.model.FundraiserType;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FundraiserRequest {

    @NotNull(message = "Shelter ID is required")
    private Long shelterId;

    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title cannot exceed 200 characters")
    private String title;

    @Size(max = 2000, message = "Description cannot exceed 2000 characters")
    private String description;

    @NotNull(message = "Goal amount is required")
    @DecimalMin(value = "1.00", message = "Goal amount must be at least 1.00")
    private BigDecimal goalAmount;

    private Currency currency = Currency.PLN;

    @NotNull(message = "Fundraiser type is required")
    private FundraiserType type = FundraiserType.GENERAL;

    private Instant endDate;

    private Boolean isMain = false;

    @Size(max = 1000, message = "Needs cannot exceed 1000 characters")
    private String needs;
}