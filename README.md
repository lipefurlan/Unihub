# UniHub

Wellness platform for university students (B2B2C): students subscribe to a monthly plan, train at partner gyms, and each gym is paid per completed check-in.

**Live:** [app.felipefurlan.com.br](https://app.felipefurlan.com.br) (student app)

This monorepo contains the three products of the proof of concept:

| Folder | Product | Stack |
|---|---|---|
| `backend/` | REST API | Python · FastAPI · SQLAlchemy · Alembic · JWT · SQLite locally, PostgreSQL in production |
| `mobile/` | Student app (iOS/Android/web) | Flutter · Riverpod · go_router · dio |
| `web_admin/` | Web dashboard for gyms **and** UniHub operations (admin) | Flutter Web · fl_chart |
| `shared_models/` | Dart DTOs, HTTP client and design system | Shared Flutter package |

The web dashboard serves two roles under the same login (the role comes from the JWT):
- **Gym** — dashboard, members, finance (statement/CSV export) and settings;
- **UniHub operations (admin)** — platform overview, gym onboarding and management (photo, commercial terms, activation), consolidated payouts with payment settlement, and the student base.

## Prerequisites

- **Python 3.11+**
- **Flutter SDK 3.44+** with web enabled (`flutter config --enable-web`)
- **Chrome** (to run the Flutter apps in web mode)

## Running locally

### 1. Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt

# Create the database (SQLite by default; set DATABASE_URL for PostgreSQL)
.\.venv\Scripts\alembic upgrade head

# Load demo data (7 plans, 10 gyms, 15 students, ~200 check-ins)
.\.venv\Scripts\python seed.py

# Start the API at http://127.0.0.1:8000
.\.venv\Scripts\uvicorn app.main:app --port 8000
```

Interactive docs (Swagger): **http://127.0.0.1:8000/docs**

> For PostgreSQL, set `DATABASE_URL=postgresql://user:pass@localhost/unihub` before `alembic upgrade head`. Models and config are portable with no changes.

### 2. Student app (mobile)

The project has Android and iOS targets; for a local demo, run it in Chrome:

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

For an Android device or emulator, run `flutter run -d <device>` with the API reachable on the network — on the emulator, use `--dart-define=UNIHUB_API=http://10.0.2.2:8000`.

### 3. Gym dashboard (web)

```powershell
cd web_admin
flutter pub get
flutter run -d chrome
```

### Demo accounts (after running the seed)

| Role | Login | Password |
|---|---|---|
| Student (Plan 3) | `joao.silva@dac.unicamp.br` | `senha123` |
| Gym (Campus Fit) | `contato@campusfit.com.br` | `academia123` |
| UniHub operations (admin) | `admin@unihub.com.br` | `admin123` |

All 15 students use the password `senha123` and all 10 gyms use `academia123` (emails are printed by `seed.py`).

**Suggested demo flow:**
1. Log into the app as João (Plan 3) → see the plan, the monthly summary and nearby gyms.
2. Check in at **Academia Campus Fit** (tier 1) → success.
3. Try to check in at **CrossBox Barão** (tier 5) → blocked with a clear message.
4. Log into the dashboard as Campus Fit → the new check-in shows up on the dashboard, in the check-in list and in the current month's finance view.
5. In Finance, open the month's breakdown and export the CSV statement.

## Core business rules (`backend/app/services/`)

- **Tier-based access:** a check-in is allowed only if `plan tier ≥ gym's minimum tier`.
- **Payout snapshot:** each check-in freezes the gym's current `valor_repasse_por_checkin` (payout per check-in); later changes don't affect past check-ins.
- **Monthly payout:** sum of the month's check-in snapshots (pending → paid; the admin settles it under Payouts).
- **Anti-fraud:** at most one check-in per student per gym every 3 hours (configurable).
- **Commercial terms:** payout amount and minimum tier are set by the admin during onboarding; the gym can see them but not change them.
- **Deactivation:** a gym deactivated by the admin disappears from the app and stops accepting check-ins (history is preserved).

## Architecture

- **Layered backend:** `routers/` (HTTP) → `services/` (business rules) → `models/` (SQLAlchemy), with Pydantic schemas at the edge. The JWT carries the `role` (`student`/`gym`) and each route requires the correct role.
- **Layered Flutter apps:** `data/` (repositories + storage) → `domain/` (local rules) → `presentation/` (Riverpod + screens). Models, the HTTP client and the design system live in `shared_models/` and are reused by the app and the dashboard.
- **Design system:** centralized tokens (`UniHubColors`, `UniHubSpacing`, `UniHubRadius`, Material theme) — white, Inter typeface, and orange `#FF5A1F` as the single accent color.

## Structure

```
unihub/
├── backend/
│   ├── app/
│   │   ├── core/        # config (DATABASE_URL), db, JWT security
│   │   ├── models/      # Student, Gym, Plan, Subscription, CheckIn, Payout
│   │   ├── schemas/     # Pydantic (API input/output)
│   │   ├── routers/     # auth, plans, gyms, students, subscriptions, checkins, gym_portal
│   │   └── services/    # checkin_service (tier/anti-fraud), payout_service (payouts)
│   ├── alembic/         # migrations
│   ├── seed.py          # demo data
│   └── requirements.txt
├── mobile/lib/
│   ├── data/            # AuthRepository, TokenStorage
│   ├── domain/          # access rules, mock geolocation
│   └── presentation/    # Riverpod providers, routes, 4 tabs + auth
├── web_admin/lib/
│   ├── data/            # GymAuthRepository, TokenStorage
│   └── presentation/    # dashboard, members, finance (CSV), settings
├── shared_models/lib/   # DTOs, ApiClient (dio), UniHub theme, formatters
├── PROGRESS.md
└── README.md
```

## Deploy

Frontends on Netlify, API and PostgreSQL on Railway. Step-by-step notes (in Portuguese) are in [`DEPLOY.md`](./DEPLOY.md).
