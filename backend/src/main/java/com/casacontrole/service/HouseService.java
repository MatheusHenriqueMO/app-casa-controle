package com.casacontrole.service;

import com.casacontrole.dto.CreateHouseRequest;
import com.casacontrole.model.House;
import com.casacontrole.security.FirebaseUserDetails;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class HouseService {

    private static final String COLLECTION = "houses";

    private Firestore db() {
        return FirestoreClient.getFirestore();
    }

    public House createHouse(CreateHouseRequest request, FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        String inviteCode = generateInviteCode();

        Map<String, Object> data = new HashMap<>();
        data.put("name", request.getName());
        data.put("inviteCode", inviteCode);
        data.put("createdBy", user.getUid());
        data.put("memberIds", List.of(user.getUid()));
        data.put("memberNames", Map.of(user.getUid(), user.getName() != null ? user.getName() : user.getEmail()));
        data.put("createdAt", Instant.now().toString());

        DocumentReference ref = db().collection(COLLECTION).document();
        ref.set(data).get();

        return getById(ref.getId());
    }

    public House joinHouse(String inviteCode, FirebaseUserDetails user)
            throws ExecutionException, InterruptedException {

        QuerySnapshot snapshot = db().collection(COLLECTION)
                .whereEqualTo("inviteCode", inviteCode.toUpperCase())
                .limit(1)
                .get().get();

        if (snapshot.isEmpty()) {
            throw new IllegalArgumentException("Código de convite inválido");
        }

        DocumentSnapshot doc = snapshot.getDocuments().get(0);
        List<String> memberIds = (List<String>) doc.get("memberIds");

        if (memberIds != null && memberIds.contains(user.getUid())) {
            return toHouse(doc);
        }

        // Adiciona o novo membro
        Map<String, Object> updates = new HashMap<>();
        updates.put("memberIds", FieldValue.arrayUnion(user.getUid()));
        updates.put("memberNames." + user.getUid(),
                user.getName() != null ? user.getName() : user.getEmail());

        doc.getReference().update(updates).get();
        return getById(doc.getId());
    }

    public House getHouse(String houseId, String uid)
            throws ExecutionException, InterruptedException {

        House house = getById(houseId);
        if (!house.getMemberIds().contains(uid)) {
            throw new SecurityException("Acesso negado");
        }
        return house;
    }

    private House getById(String id) throws ExecutionException, InterruptedException {
        DocumentSnapshot doc = db().collection(COLLECTION).document(id).get().get();
        if (!doc.exists()) throw new NoSuchElementException("Casa não encontrada");
        return toHouse(doc);
    }

    @SuppressWarnings("unchecked")
    private House toHouse(DocumentSnapshot doc) {
        Map<String, String> memberNames = (Map<String, String>) doc.get("memberNames");
        return House.builder()
                .id(doc.getId())
                .name(doc.getString("name"))
                .inviteCode(doc.getString("inviteCode"))
                .createdBy(doc.getString("createdBy"))
                .memberIds((List<String>) doc.get("memberIds"))
                .memberNames(memberNames != null ? memberNames : new HashMap<>())
                .createdAt(Instant.parse(Objects.requireNonNull(doc.getString("createdAt"))))
                .build();
    }

    private String generateInviteCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Random random = new Random();
        StringBuilder sb = new StringBuilder(6);
        for (int i = 0; i < 6; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }
}
