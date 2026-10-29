<<<<<<< HEAD
# PetVault Flutter app

This workspace now contains a Flutter prototype based on the PetVault Figma file:

https://www.figma.com/proto/6nXNZt8NsyMyECkO0Rv5TY/Petvault?node-id=32-1281

The linked `Container` frame is empty, so the app is based on the named screens elsewhere in the same Figma file. It includes the owner, marketplace, health, shopping, sitter, vendor, and trust-and-safety screen families. Use the grid button in the app to open **Explore PetVault** and jump to any included screen.

## Run

### Node.js / npm setup

The backend requires Node.js 22 or newer and npm. Install Node.js from
https://nodejs.org/ or use a version manager that reads the workspace
[.nvmrc](./.nvmrc). npm reads [backend/.npmrc](./backend/.npmrc) and rejects
unsupported Node.js versions.

From the project root, install the backend dependencies using the committed
lockfile:

```powershell
Push-Location backend
npm.cmd ci
npm.cmd test
Pop-Location
```

Use `npm.cmd` in PowerShell on Windows if the `npm` PowerShell shim is blocked
by the current execution policy. For local API development, start PostgreSQL
with Docker Compose, then run `npm.cmd run dev` from `backend`. For the web
server/API proxy, use `npm.cmd run web` from `backend` after building Flutter
Web.

For a browser running on the same computer as the backend:

```powershell
flutter pub get
flutter run -d chrome --web-port=8765
```

For a browser opened through a remote port-forward/tunnel, build and serve the
web app through the same-origin API proxy instead:

```powershell
flutter build web
Push-Location backend
npm.cmd run web
Pop-Location
```

The web server listens on port `8765`, serves `build/web`, and forwards `/api`
requests to `http://127.0.0.1:3000`. This avoids making the browser connect to
its own `127.0.0.1` and does not require permissive CORS settings. Set
`WEB_PORT` or `API_ORIGIN` to override those defaults. Keep the backend and
database running while using the web app.

The workspace's VS Code settings point Flutter to `D:\flutter` and add its
`bin` folder to new integrated terminals. If your Flutter SDK is elsewhere,
update `dart.flutterSdkPath` and the terminal PATH entry in
[.vscode/settings.json](./.vscode/settings.json). Use the **PetVault (Chrome)**
launch profile to run the app with the local backend URL configured.

## Local PostgreSQL backend

Start Docker Desktop, then run this from the project root:

```powershell
docker compose up --build -d
docker compose ps
```

Compose starts PostgreSQL on port `5432` and the API on port `3000`. Database
migrations run when the API starts. Sample accounts and records are not seeded
unless `SEED_DEMO_DATA=true` is explicitly set. Check
`http://127.0.0.1:3000/api/health` for API/database health and use
`docker compose logs -f api` to inspect startup or runtime errors. Stop the
services with `docker compose down`; database data remains in the named Docker
volume. Existing volumes keep their current rows even if demo seeding is
disabled; `docker compose down -v` deletes the local database and its data.

The Flutter web client uses `http://127.0.0.1:3000/api` for local development
and the current web origin's `/api` path when hosted remotely. For a different
API address, pass
`--dart-define=PETVAULT_API_BASE_URL=http://HOST:3000/api` to `flutter run` or
`flutter build`. Android emulators generally need
`--dart-define=PETVAULT_API_BASE_URL=http://10.0.2.2:3000/api`.
`ALLOWED_ORIGINS` in `docker-compose.yml` controls which browser origins can
call the API directly; the same-origin web proxy does not require additional
CORS origins.

In VS Code, run the **PetVault: start backend** task to build and start the
database and API; run **PetVault: stop backend** to stop them. The Flutter app
uses the API at `http://127.0.0.1:3000/api` by default. The complete database
entity-relationship diagram, including all tables and relationships, is in
[backend/ERD.md](./backend/ERD.md).

Administrator listing moderation now exposes transparent rule-based risk
signals: unusually low comparable prices, normalized duplicate titles, multiple
open reports, and unusually high seller listing volume. These scores only
prioritize human review; they never automatically reject a listing. The tests
include a small synthetic benchmark that exercises the plan's initial recall
and false-positive thresholds. It is not evidence of production model
performance; representative labeled cases and domain review are still needed.

With the stack running, the backend integration test can be run from PowerShell:

```powershell
Push-Location backend
npm.cmd test
Pop-Location
```

The root [`.env.example`](./.env.example) runs a local project demo with fixed
development OTPs and mock checkout. Copy it to `.env` and run Compose. Mock
checkout records orders but never charges a payment method. Fixed codes,
mock payments, and the local JWT secret are unsafe for production. PetVault
supports verification and password-reset email through Resend. To enable it,
verify a sender domain, add a real API key and sender address, and set
`DEV_AUTH_CODES=false`, `EMAIL_PROVIDER=resend`, `EMAIL_FROM`, and
`RESEND_API_KEY`. Set `OTP_TTL_MINUTES` from 1 to 60 (default 10). Keep API
keys out of source control. Development OTP codes work only when
`NODE_ENV` is not `production`; production startup rejects the local JWT
secret. Payments default to `unconfigured` unless `PAYMENT_PROVIDER=mock` is
explicitly selected for local demos. No identity-document upload, health-file storage,
production notification delivery, or shipping/carrier integration is
configured. Health-record creation persists record metadata and an optional
attachment name only; it does not upload the selected file bytes.

The repository is configured for Flutter Web. Flutter 3.19 or later is
required; this workspace was set up and validated with Flutter 3.47.7. To
launch from VS Code, open the project in a new VS Code window/terminal after
installing Flutter so it reloads the updated PATH.

For a production web bundle, run `flutter build web`; the output is in
`build/web`. To target native platforms, first install their toolchains and
generate their platform runners with `flutter create --platforms=windows .` or
`flutter create --platforms=android .`. Windows desktop requires Visual Studio
with the **Desktop development with C++** workload; Android requires Android
Studio and its SDK. Those native toolchains are not installed in this workspace.
The app uses local Figma source images and the Outfit font. Its production UI
starts without seeded in-memory sample accounts or records. A few workflows
that have no backend/provider implementation yet remain unavailable or
session-only; they must not be treated as completed production services.
Seller listings are account-scoped and edits return to moderation. Listing
views, visits, reviews, and production analytics are not collected. Messaging
and visit booking are not connected to backend services; the UI labels these
capabilities as unavailable rather than reporting simulated activity.

## Optional local sample accounts

These accounts are inserted only when starting a fresh database with
`SEED_DEMO_DATA=true`. They are for local testing only and are not created by
default:

| Role | Email |
| --- | --- |
| Pet owner | `owner@petvault.demo` |
| Seller (owner + seller) | `seller@petvault.demo` |
| Pet sitter | `sitter@petvault.demo` |
| Veterinarian | `vet@petvault.demo` |
| Product vendor | `vendor@petvault.demo` |
| Administrator | `admin@petvault.demo` |

When development auth codes are enabled, the demo OTP is `123456` and the
password-reset code is `654321`. These values are deliberately
non-production and must not be used for real accounts. Seeded seller, sitter,
veterinarian, and vendor accounts have approved KYC for local testing. New
accounts must submit KYC and be reviewed by an administrator before using
supply-side API routes.

## Prototype and service boundaries

Authentication, pet profiles, health-record metadata, KYC submission,
marketplace listing reads/submissions/moderation, product catalog management,
and vendor order status use the backend when signed in. Checkout is disabled
because payments and delivery are not configured. Other workflows without
backend support remain session-only or unavailable, and the backend is not a
production-ready service. It does **not** upload identity or health documents,
verify licenses, send email/SMS/push notifications, deliver messages to another
user, connect video calls, or create downloadable exports. Triage is
care-routing guidance, not diagnosis or veterinary advice. Use only synthetic
information with the local development environment.

Validate changes with:

```powershell
flutter pub get
dart format lib test
flutter test
flutter analyze
flutter build web
```
=======
# PetVault Flutter app

This workspace now contains a Flutter prototype based on the PetVault Figma file:

https://www.figma.com/proto/6nXNZt8NsyMyECkO0Rv5TY/Petvault?node-id=32-1281

The linked `Container` frame is empty, so the app is based on the named screens elsewhere in the same Figma file. It includes the owner, marketplace, health, shopping, sitter, vendor, and trust-and-safety screen families. Use the grid button in the app to open **Explore PetVault** and jump to any included screen.

## Run

### Node.js / npm setup

The backend requires Node.js 22 or newer and npm. Install Node.js from
https://nodejs.org/ or use a version manager that reads the workspace
[.nvmrc](./.nvmrc). npm reads [backend/.npmrc](./backend/.npmrc) and rejects
unsupported Node.js versions.

From the project root, install the backend dependencies using the committed
lockfile:

```powershell
Push-Location backend
npm.cmd ci
npm.cmd test
Pop-Location
```

Use `npm.cmd` in PowerShell on Windows if the `npm` PowerShell shim is blocked
by the current execution policy. For local API development, start PostgreSQL
with Docker Compose, then run `npm.cmd run dev` from `backend`. For the web
server/API proxy, use `npm.cmd run web` from `backend` after building Flutter
Web.

For a browser running on the same computer as the backend:

```powershell
flutter pub get
flutter run -d chrome --web-port=8765
```

For a browser opened through a remote port-forward/tunnel, build and serve the
web app through the same-origin API proxy instead:

```powershell
flutter build web
Push-Location backend
npm.cmd run web
Pop-Location
```

The web server listens on port `8765`, serves `build/web`, and forwards `/api`
requests to `http://127.0.0.1:3000`. This avoids making the browser connect to
its own `127.0.0.1` and does not require permissive CORS settings. Set
`WEB_PORT` or `API_ORIGIN` to override those defaults. Keep the backend and
database running while using the web app.

The workspace's VS Code settings point Flutter to `D:\flutter` and add its
`bin` folder to new integrated terminals. If your Flutter SDK is elsewhere,
update `dart.flutterSdkPath` and the terminal PATH entry in
[.vscode/settings.json](./.vscode/settings.json). Use the **PetVault (Chrome)**
launch profile to run the app with the local backend URL configured.

## Local PostgreSQL backend

Start Docker Desktop, then run this from the project root:

```powershell
docker compose up --build -d
docker compose ps
```

Compose starts PostgreSQL on port `5432` and the API on port `3000`. Database
migrations run when the API starts. Sample accounts and records are not seeded
unless `SEED_DEMO_DATA=true` is explicitly set. Check
`http://127.0.0.1:3000/api/health` for API/database health and use
`docker compose logs -f api` to inspect startup or runtime errors. Stop the
services with `docker compose down`; database data remains in the named Docker
volume. Existing volumes keep their current rows even if demo seeding is
disabled; `docker compose down -v` deletes the local database and its data.

The Flutter web client uses `http://127.0.0.1:3000/api` for local development
and the current web origin's `/api` path when hosted remotely. For a different
API address, pass
`--dart-define=PETVAULT_API_BASE_URL=http://HOST:3000/api` to `flutter run` or
`flutter build`. Android emulators generally need
`--dart-define=PETVAULT_API_BASE_URL=http://10.0.2.2:3000/api`.
`ALLOWED_ORIGINS` in `docker-compose.yml` controls which browser origins can
call the API directly; the same-origin web proxy does not require additional
CORS origins.

In VS Code, run the **PetVault: start backend** task to build and start the
database and API; run **PetVault: stop backend** to stop them. The Flutter app
uses the API at `http://127.0.0.1:3000/api` by default. The complete database
entity-relationship diagram, including all tables and relationships, is in
[backend/ERD.md](./backend/ERD.md).

Administrator listing moderation now exposes transparent rule-based risk
signals: unusually low comparable prices, normalized duplicate titles, multiple
open reports, and unusually high seller listing volume. These scores only
prioritize human review; they never automatically reject a listing. The tests
include a small synthetic benchmark that exercises the plan's initial recall
and false-positive thresholds. It is not evidence of production model
performance; representative labeled cases and domain review are still needed.

With the stack running, the backend integration test can be run from PowerShell:

```powershell
Push-Location backend
npm.cmd test
Pop-Location
```

The root [`.env.example`](./.env.example) runs a local project demo with fixed
development OTPs and mock checkout. Copy it to `.env` and run Compose. Mock
checkout records orders but never charges a payment method. Fixed codes,
mock payments, and the local JWT secret are unsafe for production. PetVault
supports verification and password-reset email through Resend. To enable it,
verify a sender domain, add a real API key and sender address, and set
`DEV_AUTH_CODES=false`, `EMAIL_PROVIDER=resend`, `EMAIL_FROM`, and
`RESEND_API_KEY`. Set `OTP_TTL_MINUTES` from 1 to 60 (default 10). Keep API
keys out of source control. Development OTP codes work only when
`NODE_ENV` is not `production`; production startup rejects the local JWT
secret. Payments default to `unconfigured` unless `PAYMENT_PROVIDER=mock` is
explicitly selected for local demos. No identity-document upload, health-file storage,
production notification delivery, or shipping/carrier integration is
configured. Health-record creation persists record metadata and an optional
attachment name only; it does not upload the selected file bytes.

The repository is configured for Flutter Web. Flutter 3.19 or later is
required; this workspace was set up and validated with Flutter 3.47.7. To
launch from VS Code, open the project in a new VS Code window/terminal after
installing Flutter so it reloads the updated PATH.

For a production web bundle, run `flutter build web`; the output is in
`build/web`. To target native platforms, first install their toolchains and
generate their platform runners with `flutter create --platforms=windows .` or
`flutter create --platforms=android .`. Windows desktop requires Visual Studio
with the **Desktop development with C++** workload; Android requires Android
Studio and its SDK. Those native toolchains are not installed in this workspace.
The app uses local Figma source images and the Outfit font. Its production UI
starts without seeded in-memory sample accounts or records. A few workflows
that have no backend/provider implementation yet remain unavailable or
session-only; they must not be treated as completed production services.
Seller listings are account-scoped and edits return to moderation. Listing
views, visits, reviews, and production analytics are not collected. Messaging
and visit booking are not connected to backend services; the UI labels these
capabilities as unavailable rather than reporting simulated activity.

## Optional local sample accounts

These accounts are inserted only when starting a fresh database with
`SEED_DEMO_DATA=true`. They are for local testing only and are not created by
default:

| Role | Email |
| --- | --- |
| Pet owner | `owner@petvault.demo` |
| Seller (owner + seller) | `seller@petvault.demo` |
| Pet sitter | `sitter@petvault.demo` |
| Veterinarian | `vet@petvault.demo` |
| Product vendor | `vendor@petvault.demo` |
| Administrator | `admin@petvault.demo` |

When development auth codes are enabled, the demo OTP is `123456` and the
password-reset code is `654321`. These values are deliberately
non-production and must not be used for real accounts. Seeded seller, sitter,
veterinarian, and vendor accounts have approved KYC for local testing. New
accounts must submit KYC and be reviewed by an administrator before using
supply-side API routes.

## Prototype and service boundaries

Authentication, pet profiles, health-record metadata, KYC submission,
marketplace listing reads/submissions/moderation, product catalog management,
and vendor order status use the backend when signed in. Checkout is disabled
because payments and delivery are not configured. Other workflows without
backend support remain session-only or unavailable, and the backend is not a
production-ready service. It does **not** upload identity or health documents,
verify licenses, send email/SMS/push notifications, deliver messages to another
user, connect video calls, or create downloadable exports. Triage is
care-routing guidance, not diagnosis or veterinary advice. Use only synthetic
information with the local development environment.

Validate changes with:

```powershell
flutter pub get
dart format lib test
flutter test
flutter analyze
flutter build web
```
>>>>>>> 24ecb6467fbec18fd7e609611217a71dd686272b
