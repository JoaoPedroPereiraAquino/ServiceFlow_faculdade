# Projeto ServiceFlow — Gestão Inteligente de O.S.

Aplicativo **Flutter / Android** offline-first para gestão de Ordens de Serviço.
Salva tudo primeiro no **SQLite** local e sincroniza automaticamente com o
**Supabase** quando a conexão volta a ficar disponível.

---

## Stack

| Camada | Tecnologia |
| --- | --- |
| UI | Flutter 3.38 · Dart 3.10 (Material 3 + Google Fonts Inter) |
| Estado | `provider` + `ChangeNotifier` (`BaseViewModel<T>`) |
| DI | `get_it` (Service Locator) |
| Rede | `dio` com `Interceptors` (JWT auto + erros padrão) |
| Backend | **Supabase** (Auth + Postgres + RLS por `user_id`) |
| Local | **SQLite** via `sqflite` + `flutter_secure_storage` |
| Sync | `connectivity_plus` + `OfflineSyncService` |
| Hardware | `image_picker` (câmera) · `signature` (assinatura digital) |
| Outros | `url_launcher` (WhatsApp / e-mail), `intl`, `uuid` |

---

## Arquitetura — Base-Driven

```
lib/
├── app/
│   ├── core/
│   │   ├── models/          # BaseModel, ErrorModel
│   │   ├── repositories/    # BaseRepository<T>
│   │   ├── viewmodels/      # BaseViewModel<T>
│   │   ├── services/        # DioClient, DatabaseHelper, ConnectivityService,
│   │   │                    # OfflineSyncService, SupabaseConfig
│   │   ├── mixins/          # UiFeedbackMixin, ValidatorMixin
│   │   ├── theme/           # AppColors, AppTheme
│   │   └── utils/           # Formatters (BRL, datas, máscaras)
│   ├── shared/widgets/      # AppLogo, CustomTextField, CustomButton,
│   │                        # AppBarCustom, AppBottomNav, StatusBadge,
│   │                        # SectionHeader, LoaderOverlay
│   ├── modules/
│   │   ├── auth/            # Login, Signup, AuthRepository
│   │   ├── dashboard/       # MainShell + Dashboard
│   │   ├── client/          # Cliente, ClienteRepository, ClientFormView
│   │   ├── service_order/   # OrdemServico, OS form/list
│   │   ├── notifications/   # NotificationsView
│   │   └── profile/         # ProfileView (logout, suporte WhatsApp)
│   └── app_setup.dart       # Inicialização e injeção de dependências
└── main.dart                # AuthGate + MaterialApp
```

### Diretrizes obrigatórias (o "Jeito ServiceFlow")
- Toda nova entidade **DEVE** herdar de `BaseModel`.
- Todo novo repositório **DEVE** herdar de `BaseRepository<T>`.
- Toda lógica de estado vive em um `Controller`/`ViewModel` que chama `notifyListeners()`.
- Proibido `print()` — use `UiFeedbackMixin.showFeedback(...)`.
- A `View` **nunca** instancia `Repository` direto — sempre via `GetIt`.
- Salvamento **sempre local primeiro** (offline-first); a API é background.

---

## Banco de Dados Supabase (projeto `ServiceFlow`)

Projeto: `rccmmsdxueijgoalqnwr` · região `sa-east-1` · Postgres 17.

Tabelas (todas com RLS `auth.uid() = user_id`):

| Tabela | Descrição |
| --- | --- |
| `profiles` | Perfil estendido do `auth.users` (nome, telefone, cargo, avaliação) |
| `clientes` | Clientes do técnico autenticado · `UNIQUE(user_id, local_id)` |
| `servicos` | Catálogo de serviços oferecidos |
| `ordens_servico` | OS com status (`aberto/execucao/executada`), `foto_*_remote_path`, assinatura base64 · `UNIQUE(user_id, local_id)` |
| `notificacoes` | Notificações do usuário |

Triggers:
- `on_auth_user_created` → cria `profiles` + notificação de boas-vindas automaticamente.
- `touch_updated_at` → mantém `updated_at` sincronizado.

> A constraint `UNIQUE(user_id, local_id)` é o que torna o sync **idempotente**:
> qualquer retry usa `upsert(onConflict: 'user_id,local_id')`, então uma OS criada
> offline jamais duplica no servidor mesmo que a sincronização seja reexecutada.

### Storage — bucket privado `os-evidencias`

- Tipo: **privado** (URLs assinadas válidas por 1h via `StorageService.signedUrlFor`).
- Limite: 10 MB · MIME aceitos: `image/jpeg`, `image/png`, `image/webp`, `image/heic`.
- Layout: `<userId>/ordens_servico/<localUuidOs>/antes_<uuid>.jpg`.
- RLS: 4 políticas (`SELECT/INSERT/UPDATE/DELETE`) que checam
  `(storage.foldername(name))[1] = auth.uid()::text`. Cada usuário só lê e escreve
  na própria pasta — impossível um técnico acessar fotos de outro.

### SQLite (espelho local — `serviceflow.db`, v2)

Cada tabela do Supabase tem sua contraparte local com colunas extras:
`local_uuid` (id estável offline), `remote_id`, `status` (`P`endente / `S`incronizado).
A tabela `ordens_servico` ainda tem `foto_antes_path`/`foto_depois_path` (caminho
local do arquivo no device) e `foto_antes_remote_path`/`foto_depois_remote_path`
(chave dentro do bucket). O `onUpgrade` migra v1 → v2 sem perder dados.

---

## Fluxo Offline-First

1. Usuário cadastra cliente / OS → grava no **SQLite** com `status='P'`
   (caminhos locais das fotos em `foto_*_path`).
2. Se houver internet, `_pushOne()` faz, **na ordem**:
   1. resolve `cliente_remote_id` consultando `clientes.remote_id` por
      `cliente_local_uuid` (cobre o caso de cliente também recém-criado offline);
   2. faz upload das fotos para o **bucket `os-evidencias`** preenchendo
      `foto_*_remote_path`;
   3. `upsert` na tabela `ordens_servico` com `onConflict: 'user_id,local_id'`
      (idempotente — pode ser repetido N vezes sem duplicar);
   4. marca `status='S'`.
3. Se qualquer passo falhar, fica como `'P'` (banner amarelo no topo do app)
   e o `OfflineSyncService` reexecuta tudo depois — sem perder fotos.
4. Quando `ConnectivityService` detecta que voltou online, `syncAll()`:
   - **push CLIENTES pendentes** (gera `remote_id`),
   - **push OS pendentes** (já consegue resolver o `cliente_id` correto),
   - **pull** das três entidades (preservando paths locais já cacheados).

Pull-to-refresh no Dashboard, Lista de OS e Notificações força um sync.

---

## Hardening de produção

### Banco (Supabase)
- RLS ativo em **todas** as 5 tabelas + bucket de Storage.
- Policies usam `(select auth.uid()) = user_id` (initplan-friendly — avalia
  uma vez por query, não por linha → escala linearmente).
- Constraint `UNIQUE(user_id, local_id)` garante idempotência do sync.
- Functions com `search_path` imutável (zero advisors de segurança).
- Índices: FK `cliente_id` + `(user_id, updated_at desc)` em todas as tabelas
  pulláveis → suporta pull incremental por cursor.

### App Flutter
- `flutter_secure_storage` (encrypted shared preferences) para refresh-token
  e cursores de sync por usuário.
- **Pull incremental por `updated_at > lastSync`** com limite de 200–500
  linhas por chamada (não baixa o histórico todo a cada sincronização).
- **Logout limpa SQLite + cursores** — outro usuário no mesmo device não vê nada.
- `AppLogger` central: em release vira no-op; ProGuard remove qualquer
  resquício de log nativo Android.
- Senha mínima: 8 caracteres com letras + dígitos (alinhado a OWASP ASVS L1).

### Android
- `usesCleartextTraffic="false"` + `network_security_config` que só permite
  HTTPS para `*.supabase.co`.
- `allowBackup="false"` + `dataExtractionRules` impedem que o Android faça
  backup automático do SQLite no Google Drive do usuário (PII de clientes).
- `extractNativeLibs="false"` (APK menor + carrega libs direto do APK).
- Build de release com **R8 + shrinkResources + proguard-rules.pro**.
- Signing config externo via `android/key.properties` (template em
  `android/key.properties.example`, gitignored).
- Recomendado para release real:
  ```bash
  flutter build appbundle --release \
    --obfuscate --split-debug-info=build/symbols
  ```

### O que ainda exige decisão humana antes do GA
- Gerar `upload-keystore.jks` e preencher `android/key.properties`.
- No Dashboard do Supabase: ativar **Leak Protection** (HaveIBeenPwned),
  **Email Confirm** obrigatório e configurar **Captcha** no Auth.
- Plug do **Sentry/Crashlytics** no `AppLogger.e` para receber crashes em
  produção (hoje só loga em debug).
- Avaliar **certificate pinning** e **detecção de root** se o app for
  manipular dados sensíveis em massa.

---

## Como executar

```bash
# 1. Instalar dependências
flutter pub get

# 2. Conectar um device Android (ou abrir um emulador)
flutter devices

# 3. Rodar em debug
flutter run

# 4. Build de release (APK ou AAB)
#    Já com obfuscação Dart + ProGuard/R8 ativo:
flutter build apk --release \
  --obfuscate --split-debug-info=build/symbols
# saída: build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
# saída: build/app/outputs/bundle/release/app-release.aab
```

> Para release na Play Store é OBRIGATÓRIO ter o `android/key.properties`
> apontando para o `upload-keystore.jks`. Sem isso o build cai pro signing
> de debug e a Play Store recusa. Veja `android/key.properties.example`.

> Já está configurado para o projeto Supabase **ServiceFlow**.
> Os credenciais públicos vivem em `lib/app/core/services/supabase_config.dart`.
> Toda a segurança é via RLS (cada usuário só enxerga as próprias linhas).

### Permissões já declaradas
- `INTERNET`, `ACCESS_NETWORK_STATE` — comunicação com Supabase
- `CAMERA`, `READ_MEDIA_IMAGES` — fotos antes/depois (RF03)
- `package com.whatsapp` (queries) — chamado emergencial via WhatsApp (RF04)

---

## Testar o fluxo completo

1. **Criar conta** (Cadastro) — o trigger no Supabase já cria seu `profiles`.
2. **Login** com o e-mail/senha.
3. No Dashboard, toque em **Novo cliente** e cadastre uma empresa.
4. Toque em **+ Nova OS**, preencha cliente, descrição, valor,
   tire as duas fotos e assine.
5. Volte ao Dashboard — os KPIs já refletem a OS.
6. Desconecte a internet (modo avião) e crie outra OS:
   ela é salva localmente com status pendente (ícone de nuvem cortada).
7. Reative a internet — o banner "Sincronizando…" aparece e a OS
   é enviada automaticamente para o Supabase.

---

## Requisitos atendidos

- **RF01** — Auth Supabase + `flutter_secure_storage` + interceptor JWT no Dio.
- **RF02** — Offline-first com fila de sync por `status='P'`.
- **RF03** — Câmera (image_picker) + assinatura digital (signature).
- **RF04** — Suporte via WhatsApp (link `wa.me`) na tela de Perfil.
- **RF05** — `CustomTextField`, `CustomButton`, `AppBarCustom`, `StatusBadge`, etc.

---

## Observações
- O design das telas espelha o protótipo de `Desing_telas/` (accent **teal**,
  bordas suaves, badges semânticos por status).
- `BottomNav` aparece apenas nas 4 telas top-level (Dashboard, Ordens,
  Notificações, Perfil) e o botão central abre **Nova OS** modal.
- O Dashboard mostra faturamento agregado, indicadores e ordens recentes —
  ao tocar em um KPI, abre a Lista de OS já filtrada.
