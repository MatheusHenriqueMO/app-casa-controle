package com.casacontrole.controller;

import com.casacontrole.dto.BalanceSummary;
import com.casacontrole.dto.CreateExpenseRequest;
import com.casacontrole.model.Expense;
import com.casacontrole.security.FirebaseUserDetails;
import com.casacontrole.service.ExpenseService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/houses/{houseId}/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @PostMapping
    public ResponseEntity<Expense> createExpense(
            @PathVariable String houseId,
            @Valid @RequestBody CreateExpenseRequest request,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(expenseService.createExpense(houseId, request, user));
    }

    @GetMapping
    public ResponseEntity<List<Expense>> listExpenses(
            @PathVariable String houseId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(expenseService.listExpenses(houseId, user, year, month));
    }

    @DeleteMapping("/{expenseId}")
    public ResponseEntity<Void> deleteExpense(
            @PathVariable String houseId,
            @PathVariable String expenseId,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        expenseService.deleteExpense(houseId, expenseId, user);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/summary")
    public ResponseEntity<BalanceSummary> getSummary(
            @PathVariable String houseId,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month,
            @AuthenticationPrincipal FirebaseUserDetails user) throws ExecutionException, InterruptedException {
        int y = year != null ? year : LocalDate.now().getYear();
        int m = month != null ? month : LocalDate.now().getMonthValue();
        return ResponseEntity.ok(expenseService.getSummary(houseId, user, y, m));
    }
}
