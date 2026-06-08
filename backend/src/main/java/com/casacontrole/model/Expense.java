package com.casacontrole.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Expense {
    private String id;
    private String houseId;
    private String description;
    private BigDecimal amount;
    private String category;         // alimentação, conta, lazer, etc.
    private String paidByUid;        // quem pagou
    private String paidByName;
    private List<String> splitWith;  // uids que dividem (null = todos da casa)
    private Instant date;
    private Instant createdAt;
    private boolean isFixed; // true = gasto fixo, false = variável
}
