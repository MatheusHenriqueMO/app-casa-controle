package com.casacontrole.controller;

import com.casacontrole.dto.CreateHouseRequest;
import com.casacontrole.dto.JoinHouseRequest;
import com.casacontrole.model.House;
import com.casacontrole.security.FirebaseUserDetails;
import com.casacontrole.service.HouseService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/houses")
public class HouseController {

    private final HouseService houseService;

    public HouseController(HouseService houseService) {
        this.houseService = houseService;
    }

    @PostMapping
    public ResponseEntity<House> createHouse(
            @Valid @RequestBody CreateHouseRequest request,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(houseService.createHouse(request, user));
    }

    @PostMapping("/join")
    public ResponseEntity<House> joinHouse(
            @Valid @RequestBody JoinHouseRequest request,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(houseService.joinHouse(request.getInviteCode(), user));
    }

    @GetMapping("/{houseId}")
    public ResponseEntity<House> getHouse(
            @PathVariable String houseId,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(houseService.getHouse(houseId, user.getUid()));
    }
}
