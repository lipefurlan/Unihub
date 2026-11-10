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

# Load demo data (7 partner universities, 1 plan, 10 gyms, 19 students, ~250 check-ins)
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
| Student (Unicamp) | `joao.silva@dac.unicamp.br` | `senha123` |
| Gym (Campus Fit) | `contato@campusfit.com.br` | `academia123` |
| UniHub operations (admin) | `admin@unihub.com.br` | `admin123` |
| University portal (FACAMP) | `programa@facamp.edu.br` | `facamp123` |

All 19 students use the password `senha123` and all 10 gyms use `academia123` (emails are printed by `seed.py`).

The login screens have one-click buttons for these demo accounts.

**Suggested demo flow** (full script in Portuguese in [`ROTEIRO-DEMO.md`](./ROTEIRO-DEMO.md)):
1. Log into the app as João → weekly goal and streak, favourite gyms, the plan (R$ 130, R$ 120 with Unicamp's subsidy).
2. Open a gym → favourite it and see its quietest hours. Check in → the success screen shows a QR and a 6-character entry code.
3. Log into the panel as Campus Fit → **Validar entrada**, type the code → entry confirmed.
4. Log in as the university (FACAMP) → adoption, usage and the monthly invoice, plus the student list.
5. Log in as the admin → monthly result (students + universities − payouts) and a "temporary password" button for students and gyms.
6. Sign up a new student with a FACAMP email → choosing the plan opens the simulated checkout (PIX or card).

Google sign-in and "forgot password" emails need a one-time setup (Google Cloud client ID and a Resend API key); see [`DEPLOY.md`](./DEPLOY.md). Without it, the Google button is hidden and the reset link is printed in the API log.

## Running the backend tests

```powershell
cd backend
.\.venv\Scripts\pip install -r requirements-dev.txt
.\.venv\Scripts\python -m pytest tests
```

## Core business rules (`backend/app/services/`)

- **Partner universities only:** students sign up (with a password or with Google) only with an email from an active partner university's domain (`universities` table).
- **Price with subsidy:** the plan costs R$ 130; the student pays that minus the university's subsidy (R$ 10 in the seed, so R$ 120). The university also pays a fixed monthly fee plus a fee per subscribed student.
- **Paid-visit cap:** gyms get R$ 8 per visit, but only for each student's first 10 visits in the month across all gyms (`MAX_PAID_CHECKINS_PER_MONTH`). Later check-ins are accepted with no payout and flagged to the gym.
- **Tier-based access:** a check-in is allowed only if `plan tier ≥ gym's minimum tier` (the seed now has a single plan, so every gym is tier 1).
- **Payout snapshot:** each check-in freezes the gym's current `valor_repasse_por_checkin` (payout per check-in); later changes don't affect past check-ins.
- **Monthly payout:** sum of the month's check-in snapshots (pending → paid; the admin settles it under Payouts).
- **Anti-fraud:** at most one check-in per student per gym every 3 hours (configurable).
- **Commercial terms:** payout amount and minimum tier are set by the admin during onboarding; the gym can see them but not change them.
- **Entry code:** each check-in gets a 6-character code (shown as a QR in the app) that the gym's reception validates in the panel; it only works at that gym and for 3 hours.
- **Pause:** a paused plan blocks check-ins until the student resumes it.
- **Weekly goal:** weeks run Monday to Sunday; the streak counts consecutive weeks with the goal met (the current week counts once it is met).
- **University portal:** a university sees how many of its students signed up, subscribe and train, plus its invoice. It never sees locations or times.
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
│   │   ├── models/      # University, Student, Gym, Plan, Subscription, CheckIn, Payout, PasswordResetToken
│   │   ├── schemas/     # Pydantic (API input/output)
│   │   ├── routers/     # auth, plans, gyms, students, subscriptions, checkins, gym_portal
│   │   └── services/    # check-in rules, payouts, universities, Google sign-in, password reset, email
│   ├── alembic/         # migrations
│   ├── tests/           # pytest
│   ├── seed.py          # demo data (business numbers at the top)
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
