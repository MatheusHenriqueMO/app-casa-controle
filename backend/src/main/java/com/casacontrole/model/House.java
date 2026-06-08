package com.casacontrole.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class House {
    private String id;
    private String name;
    private String inviteCode;       // código de 6 chars para entrar na casa
    private String createdBy;        // uid do criador
    private List<String> memberIds;  // lista de uids
    private Map<String, String> memberNames; // uid -> nome
    private Instant createdAt;
}
