package com.casacontrole.service;

import com.casacontrole.dto.CreatePaymentRequest;
import com.casacontrole.model.House;
import com.casacontrole.model.Payment;
import com.casacontrole.security.FirebaseUserDetails;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class PaymentService {

    private static final String COLLECTION = "payments";
    private final HouseService houseService;

    public PaymentService(HouseService houseService) {
        this.houseService = houseService;
    }

    private Firestore db() {
        return FirestoreClient.getFirestore();
    }

    public Payment createPayment(String houseId, CreatePaymentRequest request,
                                 FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        House house = houseService.getHouse(houseId, user.getUid());

        String toName = house.getMemberNames().getOrDefault(request.getToUid(), request.getToUid());
        String fromName = user.getName() != null ? user.getName() : user.getEmail();

        Map<String, Object> data = new HashMap<>();
        data.put("houseId", houseId);
        data.put("fromUid", user.getUid());
        data.put("fromName", fromName);
        data.put("toUid", request.getToUid());
        data.put("toName", toName);
        data.put("amount", request.getAmount().toString());
        data.put("date", Instant.now().toString());
        data.put("createdAt", Instant.now().toString());

        DocumentReference ref = db().collection(COLLECTION).document();
        ref.set(data).get();

        return toPayment(ref.get().get());
    }

    public List<Payment> listPayments(String houseId, FirebaseUserDetails user,
                                      int year, int month)
            throws ExecutionException, InterruptedException {

        houseService.getHouse(houseId, user.getUid());

        QuerySnapshot snapshot = db().collection(COLLECTION)
                .whereEqualTo("houseId", houseId)
                .get().get();

        YearMonth ym = YearMonth.of(year, month);

        return snapshot.getDocuments().stream()
                .map(this::toPayment)
                .filter(p -> YearMonth.from(p.getDate().atZone(ZoneOffset.UTC)).equals(ym))
                .sorted(Comparator.comparing(Payment::getDate).reversed())
                .collect(Collectors.toList());
    }

    public void deletePayment(String houseId, String paymentId, FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        houseService.getHouse(houseId, user.getUid());
        DocumentSnapshot doc = db().collection(COLLECTION).document(paymentId).get().get();

        if (!doc.exists()) throw new NoSuchElementException("Pagamento não encontrado");
        if (!user.getUid().equals(doc.getString("fromUid"))) {
            throw new SecurityException("Só quem fez o pagamento pode desfazê-lo");
        }

        doc.getReference().delete().get();
    }

    private Payment toPayment(DocumentSnapshot doc) {
        return Payment.builder()
                .id(doc.getId())
                .houseId(doc.getString("houseId"))
                .fromUid(doc.getString("fromUid"))
                .fromName(doc.getString("fromName"))
                .toUid(doc.getString("toUid"))
                .toName(doc.getString("toName"))
                .amount(new BigDecimal(Objects.requireNonNull(doc.getString("amount"))))
                .date(Instant.parse(Objects.requireNonNull(doc.getString("date"))))
                .createdAt(Instant.parse(Objects.requireNonNull(doc.getString("createdAt"))))
                .build();
    }
}
