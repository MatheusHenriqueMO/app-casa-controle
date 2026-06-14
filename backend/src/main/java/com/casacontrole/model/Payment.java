package com.casacontrole.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Payment {
    private String id;
    private String houseId;
    private String fromUid;
    private String fromName;
    private String toUid;
    private String toName;
    private BigDecimal amount;
    private Instant date;
    private Instant createdAt;
}
