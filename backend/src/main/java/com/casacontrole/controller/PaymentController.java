package com.casacontrole.controller;

import com.casacontrole.dto.CreatePaymentRequest;
import com.casacontrole.model.Payment;
import com.casacontrole.security.FirebaseUserDetails;
import com.casacontrole.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/houses/{houseId}/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping
    public ResponseEntity<Payment> createPayment(
            @PathVariable String houseId,
            @Valid @RequestBody CreatePaymentRequest request,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(paymentService.createPayment(houseId, request, user));
    }

    @GetMapping
    public ResponseEntity<List<Payment>> listPayments(
            @PathVariable String houseId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        int y = year != null ? year : LocalDate.now().getYear();
        int m = month != null ? month : LocalDate.now().getMonthValue();
        return ResponseEntity.ok(paymentService.listPayments(houseId, user, y, m));
    }
}
