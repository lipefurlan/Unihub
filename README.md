# UniHub — POC

Plataforma agregadora de bem-estar para universitários ("Wellhub para estudante"), modelo **B2B2C com repasse por check-in**: o estudante assina um plano mensal, treina em academias parceiras, e a academia recebe por cada check-in efetivado.

Este monorepo contém os três produtos do POC:

| Pasta | Produto | Stack |
|---|---|---|
| `backend/` | API REST | Python · FastAPI · SQLAlchemy · SQLite (pronto p/ PostgreSQL) · JWT · Alembic |
| `mobile/` | App do estudante (iOS/Android) | Flutter · Riverpod · go_router · dio |
| `web_admin/` | Painel web: academia **e** operação UniHub (admin) | Flutter Web · fl_chart |
| `shared_models/` | DTOs Dart + cliente HTTP + design system | Package Flutter compartilhado |

O painel web atende dois perfis no mesmo login (o role vem no JWT):
- **Academia** — dashboard, alunos, financeiro (extrato/CSV) e configurações;
- **Operação UniHub (admin)** — visão geral da plataforma, credenciamento e gestão
  das academias (incl. foto, cláusulas comerciais e ativação), repasses consolidados
  com baixa de pagamento e base de estudantes.

## Pré-requisitos

- **Python 3.11+**
- **Flutter SDK 3.44+** (com suporte web habilitado: `flutter config --enable-web`)
- **Chrome** (para rodar os apps Flutter em modo web)

## 1. Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt

# Cria o banco (SQLite por padrão; defina DATABASE_URL p/ PostgreSQL)
.\.venv\Scripts\alembic upgrade head

# Popula dados de demonstração (7 planos, 10 academias, 15 estudantes, ~200 check-ins)
.\.venv\Scripts\python seed.py

# Sobe a API em http://127.0.0.1:8000
.\.venv\Scripts\uvicorn app.main:app --port 8000
```

Documentação interativa (Swagger): **http://127.0.0.1:8000/docs**

> Para PostgreSQL: `set DATABASE_URL=postgresql://user:pass@localhost/unihub` antes do
> `alembic upgrade head` — models e config são portáveis, sem refatoração.

## 2. App do estudante (mobile)

O projeto tem targets Android e iOS; para a demo local rodamos no Chrome:

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

(Para dispositivo/emulador Android: `flutter run -d <device>` com a API acessível
pela rede — use `--dart-define=UNIHUB_API=http://10.0.2.2:8000` no emulador.)

## 3. Painel da academia (web)

```powershell
cd web_admin
flutter pub get
flutter run -d chrome
```

## Credenciais de teste (após o seed)

| Perfil | Login | Senha |
|---|---|---|
| Estudante (Plano 3) | `joao.silva@dac.unicamp.br` | `senha123` |
| Academia (Campus Fit) | `contato@campusfit.com.br` | `academia123` |
| Operação UniHub (admin) | `admin@unihub.com.br` | `admin123` |

Todos os 15 estudantes usam a senha `senha123`; todas as 10 academias, `academia123`
(e-mails listados na saída do `seed.py`).

**Roteiro de demo sugerido:**
1. Logue no app como João (Plano 3) → veja plano, resumo do mês e academias próximas.
2. Faça check-in na **Academia Campus Fit** (tier 1) → sucesso.
3. Tente check-in no **CrossBox Barão** (tier 5) → bloqueio com mensagem clara.
4. Logue no painel como Campus Fit → o check-in recém-feito aparece no dashboard,
   na lista de check-ins e no financeiro do mês corrente.
5. No Financeiro, abra o detalhamento do mês e exporte o extrato CSV.

## Regras de negócio principais (`backend/app/services/`)

- **Acesso por tier:** check-in permitido apenas se `tier do plano ≥ tier mínimo da academia`.
- **Snapshot de repasse:** cada check-in congela o `valor_repasse_por_checkin` vigente da academia; alterações futuras não afetam check-ins passados.
- **Repasse mensal:** soma dos snapshots dos check-ins do mês (pendente → pago; a baixa é feita pelo admin em Repasses).
- **Anti-fraude:** máximo 1 check-in por aluno/academia a cada 3 horas (configurável).
- **Cláusulas comerciais:** valor de repasse e tier mínimo são definidos pelo admin no credenciamento; a academia visualiza mas não altera.
- **Desativação:** academia desativada pelo admin some do app e não aceita check-ins (histórico preservado).

## Arquitetura

- **Backend em camadas:** `routers/` (HTTP) → `services/` (regras de negócio) → `models/` (SQLAlchemy). Schemas Pydantic na borda. JWT carrega o `role` (`student`/`gym`) e cada rota exige o role correto.
- **Flutter em camadas:** `data/` (repositórios + storage) → `domain/` (regras locais) → `presentation/` (Riverpod + telas). Modelos, cliente HTTP e o design system ficam em `shared_models/` e são reutilizados pelo app e pelo painel.
- **Design system:** tokens centralizados (`UniHubColors`, `UniHubSpacing`, `UniHubRadius`, tema Material) — branco, tipografia Inter e laranja `#FF5A1F` como única cor de acento.

## Estrutura

```
unihub/
├── backend/
│   ├── app/
│   │   ├── core/        # config (DATABASE_URL), db, segurança JWT
│   │   ├── models/      # Student, Gym, Plan, Subscription, CheckIn, Payout
│   │   ├── schemas/     # Pydantic (entrada/saída da API)
│   │   ├── routers/     # auth, plans, gyms, students, subscriptions, checkins, gym_portal
│   │   └── services/    # checkin_service (tier/anti-fraude), payout_service (repasses)
│   ├── alembic/         # migrations
│   ├── seed.py          # dados de demonstração
│   └── requirements.txt
├── mobile/lib/
│   ├── data/            # AuthRepository, TokenStorage
│   ├── domain/          # regras de acesso, geolocalização mock
│   └── presentation/    # providers Riverpod, rotas, 4 abas + auth
├── web_admin/lib/
│   ├── data/            # GymAuthRepository, TokenStorage
│   └── presentation/    # dashboard, alunos, financeiro (CSV), configurações
├── shared_models/lib/   # DTOs, ApiClient (dio), tema UniHub, formatadores
├── PROGRESS.md
└── README.md
```
