package com.casacontrole.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateHouseRequest {
    @NotBlank(message = "Nome da casa é obrigatório")
    private String name;
}
