package com.casacontrole.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BalanceSummary {
    private BigDecimal totalMonth;
    private Map<String, BigDecimal> totalByCategory;    // categoria -> total
    private Map<String, BigDecimal> paidByMember;       // uid -> quanto pagou
    private Map<String, BigDecimal> owedByMember;       // uid -> quanto deve
    private List<DebtSettlement> settlements;            // quem paga quem

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DebtSettlement {
        private String fromUid;
        private String fromName;
        private String toUid;
        private String toName;
        private BigDecimal amount;
    }
}
