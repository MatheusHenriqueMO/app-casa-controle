# Casa Controle 🏠

App de controle de gastos compartilhados por casa, com múltiplos usuários, login Google e divisão automática de contas.

## Arquitetura

```
app_casa_controle/
├── backend/        → Java 17 + Spring Boot 3 + Firebase Admin SDK
├── frontend/       → Flutter + Firebase Auth + Google Sign-In
└── firestore.rules → Regras de segurança do Firestore
```

---

## Configuração do Firebase

### 1. Crie o projeto no Firebase Console
- Acesse https://console.firebase.google.com
- Crie um novo projeto

### 2. Ative Authentication
- Vá em Authentication > Sign-in method
- Ative o provedor **Google**

### 3. Crie o Firestore
- Vá em Firestore Database > Criar banco de dados
- Escolha **produção** ou **teste** (use as regras em `firestore.rules`)

### 4. Faça upload das regras do Firestore
```bash
firebase deploy --only firestore:rules
```

---

## Backend (Spring Boot)

### Pré-requisitos
- Java 17+
- Maven 3.8+

### Configuração

1. No Firebase Console, vá em **Configurações do Projeto > Contas de Serviço**
2. Clique em **Gerar nova chave privada** e baixe o JSON
3. Salve como `backend/src/main/resources/firebase-service-account.json`

### Rodando localmente
```bash
cd backend
mvn spring-boot:run
```

A API sobe em `http://localhost:8080`

### Deploy (exemplo com Railway)
```bash
# Configure a variável de ambiente com o conteúdo do JSON da service account
# GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
mvn package -DskipTests
# Faça upload do JAR gerado em target/
```

---

## Frontend (Flutter)

### Pré-requisitos
- Flutter 3.x
- Dart 3.x
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### Configuração do Firebase no Flutter

```bash
cd frontend
flutter pub get

# Configure o Firebase (requer firebase-tools instalado)
flutterfire configure
# Isso gera/atualiza o arquivo lib/firebase_options.dart automaticamente
```

### Android — SHA-1 para Google Sign-In
```bash
# Debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Copie o SHA-1 e adicione no Firebase Console > Configurações do Projeto > Android > SHA-1
```

### Rodando
```bash
flutter run
```

### URL do backend
Edite `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://SEU_SERVIDOR/api';
```

---

## Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/houses` | Criar casa |
| POST | `/api/houses/join` | Entrar por código |
| GET | `/api/houses/{id}` | Detalhes da casa |
| POST | `/api/houses/{id}/expenses` | Adicionar gasto |
| GET | `/api/houses/{id}/expenses` | Listar gastos (`?year=&month=`) |
| DELETE | `/api/houses/{id}/expenses/{eid}` | Excluir gasto |
| GET | `/api/houses/{id}/expenses/summary` | Resumo/acertos (`?year=&month=`) |

Todos os endpoints exigem `Authorization: Bearer <firebase-id-token>`.

---

## Funcionalidades

- ✅ Login com Google
- ✅ Criar casa com nome
- ✅ Gerar código de convite de 6 caracteres
- ✅ Entrar em casa por código
- ✅ Registrar gastos com categoria, valor, data e divisão customizada
- ✅ Listar gastos por mês
- ✅ Dashboard com gráfico por categoria
- ✅ Cálculo automático de acertos (quem deve pagar quem)
- ✅ Regras de segurança no Firestore
