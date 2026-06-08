package com.casacontrole.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    @Value("${app.firebase.credentials-path:#{null}}")
    private Resource credentialsResource;

    @Value("${FIREBASE_CREDENTIALS_JSON:#{null}}")
    private String credentialsJson;

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            GoogleCredentials credentials;
            if (credentialsJson != null && !credentialsJson.isBlank()) {
                // Variável de ambiente (Railway/produção)
                credentials = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(credentialsJson.getBytes(StandardCharsets.UTF_8))
                );
            } else {
                // Arquivo local (desenvolvimento)
                credentials = GoogleCredentials.fromStream(credentialsResource.getInputStream());
            }
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();
            return FirebaseApp.initializeApp(options);
        }
        return FirebaseApp.getInstance();
    }
}
