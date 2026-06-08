package com.casacontrole.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class JoinHouseRequest {
    @NotBlank(message = "Código de convite é obrigatório")
    private String inviteCode;
}
