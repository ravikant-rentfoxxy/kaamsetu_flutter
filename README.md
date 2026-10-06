# KaamDhaam — Flutter + GetX

A standalone Flutter port of the KaamSetu React Native app (`kaansetu-main/apps/mobile`), using **GetX** for state management, routing and dependency injection. It talks to the same Express API (`kaansetu-main/packages/api`), which is unchanged. Both roles are covered:

- **Worker:** language picker, OTP login, 5-step quick profile, dashboard (jobs / applied / offers, notifications), job browsing with filters, 5-step KYC, profile with Refer & Earn, detailed profile forms, the blocked-profile screen and the offer letter.
- **Employer:** registration, business verification, dashboard (posts / applicants / shortlist / hires), posting requirements, matched profiles, worker search, worker detail, shortlisting, hiring with e-sign, and case alerts.

## Run it

```bash
cd kaamsetu_flutter
flutter pub get
flutter run                 # demo mode (default): no backend needed
```

### Sample credentials (demo mode)

Every account uses the OTP **`123456`**. The login screen lists these accounts; tap one to fill the form.

| Mobile       | Role     | What you'll see |
|--------------|----------|-----------------|
| `9876543210` | Worker   | Ramesh Kumar: verified, matched jobs, a pending offer, 250 referral points |
| `9123456789` | Employer | Sharma Logistics: posts, 3 applicants, a shortlist, hires (one waiting for e-sign), a case alert |
| `9000000001` | Worker   | A new signup: quick profile, then KYC, which unlocks jobs |
| `9000000003` | Worker   | A blocked profile (a case was found during a periodic check) |
| any other    | either   | A new account with the role you pick |

Referral code to try with a new worker: `SURE4K9P`. Use **"Reset demo data"** on the login screen to restore the seed data.

### Against the real backend

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_URL=http://10.0.2.2:3000
```

`DEV_KYC=true` (the default) uses the backend's `/kyc/mock-*` endpoints, the same way the RN app's `IS_DEV` does. In non-production environments the backend also accepts OTP `123456`.

## Architecture

```
lib/
├── main.dart                     # GetStorage, AuthService, ApiClient (mock | http), GetMaterialApp
├── app/
│   ├── config/app_config.dart    # USE_MOCK / API_URL / DEV_KYC, sample credentials
│   ├── data/
│   │   ├── api/                  # ApiClient interface, GetConnect client (JWT + refresh), demo backend + seed
│   │   ├── models/               # typed views over Prisma JSON
│   │   ├── repositories/         # Auth / Worker / Employer endpoint wrappers
│   │   ├── services/             # AuthService (session + language), Session (login/logout routing)
│   │   └── stores/               # WorkerStore / EmployerStore: shared reactive cache (replaces RTK Query)
│   ├── i18n/                     # GetX Translations (hi / en), ported from utils/i18n.ts
│   ├── routes/                   # route names + GetPages with bindings
│   ├── theme/                    # design tokens and job-type icon/colour metadata from the RN theme
│   └── widgets/                  # Button, Input, AlertCard, chips, cards, sheets, dialogs, JobCard
└── modules/
    ├── auth/  worker/  employer/  shared/   # GetView screens + GetxControllers
```

How the RN pieces map to GetX:

| React Native | Flutter |
|---|---|
| Redux `authSlice` + SecureStore | `AuthService` + GetStorage |
| RTK Query cache and tag invalidation | `WorkerStore` / `EmployerStore` (`Rx` lists, explicit `refresh*()`) |
| React Navigation stacks/tabs | GetX named routes + bindings; `TabShell` with `IndexedStack` |
| `useT()` / `t()` | `'key'.tr`, plus `l(en, hi)` for one-off strings |

The demo backend (`lib/app/data/api/mock/`) reproduces the Express routes: the 100-point matching algorithm with haversine distance, the KYC state machine, the shortlist → hire → e-sign → accept lifecycle, notifications, and referral points and rewards. Its state is saved to device storage, so a demo session survives app restarts.

## Tests

```bash
flutter analyze
flutter test
```

- `test/mock_backend_test.dart` runs end-to-end API flows for every sample account.
- `test/screens_smoke_test.dart` renders every screen at a 360×780 phone size, drives login, quick onboarding and the full KYC flow, and fails on any layout overflow.

## Not ported (yet)

- **GPS location detection:** pincode lookup (India Post API) and approximate city coordinates are used instead.
- **Camera selfie and PDF upload:** the dev/mock KYC endpoints are used, as in the RN app's dev builds.
- **SMS auto-read and phone-number hint:** these were stubs in the RN app too.
- **Push notifications (FCM):** notifications are shown in-app.
