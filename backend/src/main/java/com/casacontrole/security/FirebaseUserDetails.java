package com.casacontrole.security;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class FirebaseUserDetails {
    private String uid;
    private String email;
    private String name;
}
