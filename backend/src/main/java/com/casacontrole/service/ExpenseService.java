package com.casacontrole.service;

import com.casacontrole.dto.BalanceSummary;
import com.casacontrole.dto.CreateExpenseRequest;
import com.casacontrole.model.Expense;
import com.casacontrole.model.House;
import com.casacontrole.security.FirebaseUserDetails;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class ExpenseService {

    private static final String COLLECTION = "expenses";
    private final HouseService houseService;

    public ExpenseService(HouseService houseService) {
        this.houseService = houseService;
    }

    private Firestore db() {
        return FirestoreClient.getFirestore();
    }

    public Expense createExpense(String houseId, CreateExpenseRequest request,
                                 FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        House house = houseService.getHouse(houseId, user.getUid());

        List<String> splitWith = request.getSplitWith();
        if (splitWith == null || splitWith.isEmpty()) {
            splitWith = house.getMemberIds();
        }

        Instant date = request.getDate() != null ? request.getDate() : Instant.now();

        Map<String, Object> data = new HashMap<>();
        data.put("houseId", houseId);
        data.put("description", request.getDescription());
        data.put("amount", request.getAmount().toString());
        data.put("category", request.getCategory());
        data.put("paidByUid", user.getUid());
        data.put("paidByName", user.getName() != null ? user.getName() : user.getEmail());
        data.put("splitWith", splitWith);
        data.put("date", date.toString());
        data.put("createdAt", Instant.now().toString());
        data.put("isFixed", request.isFixed());

        DocumentReference ref = db().collection(COLLECTION).document();
        ref.set(data).get();

        return toExpense(ref.get().get());
    }

    public List<Expense> listExpenses(String houseId, FirebaseUserDetails user,
                                      Integer year, Integer month)
            throws ExecutionException, InterruptedException {

        houseService.getHouse(houseId, user.getUid());

        QuerySnapshot snapshot = db().collection(COLLECTION)
                .whereEqualTo("houseId", houseId)
                .get().get();

        List<Expense> expenses = snapshot.getDocuments().stream()
                .map(this::toExpense)
                .collect(Collectors.toList());

        // Filtro por mês/ano se fornecido
        if (year != null && month != null) {
            YearMonth ym = YearMonth.of(year, month);
            expenses = expenses.stream()
                    .filter(e -> {
                        YearMonth eym = YearMonth.from(e.getDate().atZone(ZoneOffset.UTC));
                        return eym.equals(ym);
                    })
                    .collect(Collectors.toList());
        }

        expenses.sort(Comparator.comparing(Expense::getDate).reversed());
        return expenses;
    }

    public void deleteExpense(String houseId, String expenseId, FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        houseService.getHouse(houseId, user.getUid());
        DocumentSnapshot doc = db().collection(COLLECTION).document(expenseId).get().get();

        if (!doc.exists()) throw new NoSuchElementException("Gasto não encontrado");
        if (!user.getUid().equals(doc.getString("paidByUid"))) {
            throw new SecurityException("Só quem criou pode deletar");
        }

        doc.getReference().delete().get();
    }

    public BalanceSummary getSummary(String houseId, FirebaseUserDetails user,
                                     int year, int month,
                                     PaymentService paymentService)
            throws ExecutionException, InterruptedException {

        House house = houseService.getHouse(houseId, user.getUid());
        List<Expense> expenses = listExpenses(houseId, user, year, month);
        List<com.casacontrole.model.Payment> payments = paymentService.listPayments(houseId, user, year, month);

        BigDecimal totalMonth = BigDecimal.ZERO;
        Map<String, BigDecimal> totalByCategory = new HashMap<>();
        Map<String, BigDecimal> paidByMember = new HashMap<>();
        Map<String, BigDecimal> owedByMember = new HashMap<>();

        // Inicializa todos os membros com zero
        for (String uid : house.getMemberIds()) {
            paidByMember.put(uid, BigDecimal.ZERO);
            owedByMember.put(uid, BigDecimal.ZERO);
        }

        for (Expense expense : expenses) {
            totalMonth = totalMonth.add(expense.getAmount());

            // Por categoria
            totalByCategory.merge(expense.getCategory(), expense.getAmount(), BigDecimal::add);

            // Quem pagou
            paidByMember.merge(expense.getPaidByUid(), expense.getAmount(), BigDecimal::add);

            // Quanto cada um deve da divisão
            List<String> splitWith = expense.getSplitWith();
            if (splitWith != null && !splitWith.isEmpty()) {
                BigDecimal share = expense.getAmount()
                        .divide(BigDecimal.valueOf(splitWith.size()), 2, RoundingMode.HALF_UP);
                for (String uid : splitWith) {
                    owedByMember.merge(uid, share, BigDecimal::add);
                }
            }
        }

        // Balances: positivo = receber, negativo = pagar
        Map<String, BigDecimal> balance = new HashMap<>();
        for (String uid : house.getMemberIds()) {
            BigDecimal paid = paidByMember.getOrDefault(uid, BigDecimal.ZERO);
            BigDecimal owed = owedByMember.getOrDefault(uid, BigDecimal.ZERO);
            balance.put(uid, paid.subtract(owed));
        }

        // Descontar pagamentos já realizados
        for (com.casacontrole.model.Payment payment : payments) {
            // quem pagou aumenta seu saldo (como se tivesse "recebido" o que era devido)
            balance.merge(payment.getFromUid(), payment.getAmount(), BigDecimal::add);
            // quem recebeu diminui seu saldo
            balance.merge(payment.getToUid(), payment.getAmount().negate(), BigDecimal::add);
        }

        List<BalanceSummary.DebtSettlement> settlements = calculateSettlements(balance, house.getMemberNames());

        return BalanceSummary.builder()
                .totalMonth(totalMonth)
                .totalByCategory(totalByCategory)
                .paidByMember(paidByMember)
                .owedByMember(owedByMember)
                .settlements(settlements)
                .build();
    }

    private List<BalanceSummary.DebtSettlement> calculateSettlements(
            Map<String, BigDecimal> balance, Map<String, String> memberNames) {

        List<BalanceSummary.DebtSettlement> settlements = new ArrayList<>();
        Map<String, BigDecimal> mutableBalance = new HashMap<>(balance);

        List<Map.Entry<String, BigDecimal>> creditors = mutableBalance.entrySet().stream()
                .filter(e -> e.getValue().compareTo(BigDecimal.ZERO) > 0)
                .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                .collect(Collectors.toList());

        List<Map.Entry<String, BigDecimal>> debtors = mutableBalance.entrySet().stream()
                .filter(e -> e.getValue().compareTo(BigDecimal.ZERO) < 0)
                .sorted(Map.Entry.comparingByValue())
                .collect(Collectors.toList());

        int ci = 0, di = 0;
        while (ci < creditors.size() && di < debtors.size()) {
            String creditorUid = creditors.get(ci).getKey();
            String debtorUid = debtors.get(di).getKey();
            BigDecimal credit = mutableBalance.get(creditorUid);
            BigDecimal debt = mutableBalance.get(debtorUid).negate();
            BigDecimal amount = credit.min(debt);

            settlements.add(BalanceSummary.DebtSettlement.builder()
                    .fromUid(debtorUid)
                    .fromName(memberNames.getOrDefault(debtorUid, debtorUid))
                    .toUid(creditorUid)
                    .toName(memberNames.getOrDefault(creditorUid, creditorUid))
                    .amount(amount)
                    .build());

            mutableBalance.put(creditorUid, credit.subtract(amount));
            mutableBalance.put(debtorUid, debt.subtract(amount).negate());

            if (mutableBalance.get(creditorUid).compareTo(BigDecimal.ZERO) == 0) ci++;
            if (mutableBalance.get(debtorUid).compareTo(BigDecimal.ZERO) == 0) di++;
        }

        return settlements;
    }

    private Expense toExpense(DocumentSnapshot doc) {
        return Expense.builder()
                .id(doc.getId())
                .houseId(doc.getString("houseId"))
                .description(doc.getString("description"))
                .amount(new BigDecimal(Objects.requireNonNull(doc.getString("amount"))))
                .category(doc.getString("category"))
                .paidByUid(doc.getString("paidByUid"))
                .paidByName(doc.getString("paidByName"))
                .splitWith((List<String>) doc.get("splitWith"))
                .date(Instant.parse(Objects.requireNonNull(doc.getString("date"))))
                .createdAt(Instant.parse(Objects.requireNonNull(doc.getString("createdAt"))))
                .isFixed(Boolean.TRUE.equals(doc.getBoolean("isFixed")))
                .build();
    }
}
