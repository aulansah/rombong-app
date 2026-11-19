# Rombong — aplikasi Flutter

Flutter client for [rombong-api](https://github.com/aulansah/rombong-api), built with
**Clean Architecture** and **Riverpod 3** (providers, `AsyncNotifier`, `AsyncValue`, provider overrides for testing, dependency injection through Riverpod).

![Flutter CI](https://github.com/aulansah/rombong-app/actions/workflows/flutter-ci.yml/badge.svg)

## Design

Figma file: [E-Commerce App — UI Design](https://www.figma.com/design/B9ckLWw2BNWUWNO3h5zdqa). Its `Color`/`Size` variables and text styles map 1:1 to `lib/core/theme/app_theme.dart` (`AppColors`, `AppSizes`, `AppTextStyles`), and its components (Button, TextField, CategoryChip, ProductCard) map to widgets of the same name.

## Progress

- [x] **Phase 1** — foundation + auth: login, register, saved session, automatic token refresh, logout
- [x] **Phase 2** — product catalog: list, debounced search, category filter, infinite scroll, pull-to-refresh, detail (UI follows the Figma tokens and components)
- [x] **Phase 3** — cart: add from product detail, badge, change quantity and remove with optimistic updates, clear, unavailable-item warning
- [x] **Phase 4** — checkout (review, double-tap guard, stock-conflict handling) and order history (paginated list, detail with status timeline, cancel)
- [x] **Phase 5** — payment: Idempotency-Key persisted per order (safe retry, resume after restart), simulated success/decline, expiry countdown, new attempt after failure
- [x] **Phase 6** — admin: products (create, edit, stock, delete), categories, all orders with status changes; hidden for customers and enforced by the backend
- [x] CI — GitHub Actions: `flutter analyze` + `flutter test --coverage` on every push and pull request

## Quick start

1. **Run the backend** (in the `ECommerce API` folder):

   ```bash
   docker compose up --build -d
   curl.exe http://localhost:8080/health
   ```

2. **Check your Flutter version** — this app needs Flutter 3.35+ (Dart 3.9+):

   ```bash
   flutter --version   # if older: flutter upgrade
   ```

3. **Generate platform folders** (first time only; existing files are kept):

   ```bash
   flutter create --org com.aulansah --project-name rombong .
   ```

4. **Install packages, check, test:**

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```

5. **Run:**

   | Target | Command | API URL used |
   |---|---|---|
   | Android emulator | `flutter run` | `http://10.0.2.2:8080/api/v1` |
   | Chrome | `flutter run -d chrome --web-port 3000` | `http://localhost:8080/api/v1` |
   | Windows desktop / iOS simulator | `flutter run` | `http://localhost:8080/api/v1` |
   | Physical phone (same Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<laptop-ip>:8080/api/v1` | your laptop's IP |

   Log in with the seeded admin `admin@example.com` / `Admin12345`, or register a new account.

## Architecture

```
lib/
  core/                       shared by every feature
    providers.dart            Dio, TokenStorage, SessionEvents as providers
    config/env.dart           API base URL per platform
    error/failure.dart        sealed Failure types
    result.dart               sealed Result<T> = Ok | Err
    usecase.dart              UseCase<T, Params> contract
    network/                  Dio client, AuthInterceptor (token refresh), error mapping
    storage/                  secure token storage
    router/                   go_router driven by the session provider
  features/
    auth/
      domain/                 entities, repository contract, use cases   ← pure Dart
      data/                   JSON models, remote data source, repository implementation
      auth_providers.dart     DI wiring: data → domain, as providers
      presentation/
        controllers/          AuthController (session), Login/Register controllers (autoDispose)
        pages/
```

Dependencies point inward: `presentation → domain ← data`. The domain layer
imports neither Flutter, Riverpod nor Dio — switching this app from Bloc to
Riverpod only touched `presentation/` and the DI wiring.

Request flow:

```
Page (ref.read) → Notifier → UseCase → Repository (interface) → RepositoryImpl → RemoteDataSource → Dio → Go API
                 ↑ state = AsyncLoading / AsyncData / AsyncError ← Result<T>
```

Session state is `AsyncValue<User?>` in `authControllerProvider`:
`AsyncLoading` = checking the saved session (splash), `AsyncData(user)` =
signed in, `AsyncData(null)` = signed out. The router listens to it.

## Testing

| Test | What it proves |
|---|---|
| `test/features/auth/auth_controller_test.dart` | Session restore, offline startup, logout, session expiry — with use cases overridden via `ProviderContainer.test(overrides: ...)` |
| `test/features/auth/login_controller_test.dart` | `AsyncValue` sequence idle → loading → data/error, 422 field errors, double tap ignored |
| `test/features/auth/auth_usecases_test.dart` | Use cases with a mocked repository (`Register` = register then login) |
| `test/features/auth/auth_repository_impl_test.dart` | Tokens saved on login, dead sessions cleared, logout works offline |
| `test/core/network/auth_interceptor_test.dart` | Three concurrent 401s trigger **one** token refresh |
| `test/widget_test.dart` | Login page shows backend errors (`ProviderScope` overrides) and validates locally |

## Troubleshooting

| Problem | Fix |
|---|---|
| "Tidak bisa terhubung ke server" | Backend not running, or wrong URL for your target (see table above). On a physical phone use the laptop IP and allow port 8080 in Windows Firewall. |
| Chrome: CORS error | Run with `--web-port 3000`; the backend only allows `http://localhost:3000`. |
| Android: "Cleartext HTTP traffic not permitted" | Add `android:usesCleartextTraffic="true"` to `<application>` in `android/app/src/debug/AndroidManifest.xml` (debug builds only). |
| Android build: minSdk error from flutter_secure_storage | Set `minSdk = 23` (or higher) in `android/app/build.gradle(.kts)`. |
| `pub get` version conflict | Run `flutter --version` and share the output; the version ranges may need adjusting for your SDK. |
