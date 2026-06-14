package com.casacontrole.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
public class UpdateExpenseRequest {
    @NotBlank
    private String description;

    @NotNull
    @Positive
    private BigDecimal amount;

    @NotBlank
    private String category;

    private List<String> splitWith;

    private Instant date;

    private boolean isFixed;
}
