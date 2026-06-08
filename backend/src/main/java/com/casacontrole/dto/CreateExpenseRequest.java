package com.casacontrole.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
public class CreateExpenseRequest {
    @NotBlank(message = "Descrição é obrigatória")
    private String description;

    @NotNull
    @Positive(message = "Valor deve ser positivo")
    private BigDecimal amount;

    @NotBlank(message = "Categoria é obrigatória")
    private String category;

    private List<String> splitWith; // null = divide com todos

    private Instant date; // null = agora

    private boolean isFixed; // true = gasto fixo, false = variável
}
