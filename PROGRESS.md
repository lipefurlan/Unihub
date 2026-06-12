# PROGRESS — POC UniHub

## Status: POC completo + área de administração da plataforma

### Etapa G — Operação UniHub (admin/backoffice)
- [x] Backend: model `Admin` + migration (`admins`, `gyms.is_active`), role `admin` no JWT (mesmo `POST /auth/login`), guarda `get_current_admin`.
- [x] Rotas `/admin/*`: overview da plataforma (receita de assinaturas × repasses = margem, top academias), CRUD de academias (credenciamento com e-mail/senha, edição das cláusulas comerciais, ativar/desativar), upload de foto (servida em `/uploads`), repasses consolidados por mês com `mark-paid` (upsert de Payout), base de estudantes.
- [x] Regras: academia desativada some do app e bloqueia check-in; valor de repasse/tier mínimo saíram da edição da academia (somente leitura no painel dela — cláusula de contrato).
- [x] Frontend: sessão por role no painel (mesmo login), menu lateral muda conforme o perfil; telas Visão geral, Academias (formulário de credenciamento + foto via file picker + ativação), Repasses (seletor de mês + baixa com confirmação) e Estudantes. Itens de menu com `Semantics` (acessibilidade).
- [x] Seed: admin `admin@unihub.com.br` / `admin123`.
- [x] **Checkpoints:** via curl — overview com margem correta, criação de academia (201 + login dela funcionando), 403 para token de academia em `/admin/*`, campo de repasse ignorado no PUT da academia, mark-paid de maio, upload de foto servida com HTTP 200, desativação removendo da lista pública. Visual — login admin, visão geral, lista de academias com fotos/cláusulas, repasse do Campus Fit marcado como pago (pendente caiu R$ 371 → R$ 331, selo "Pago" com data).

### Etapa 0 — Ambiente
- [x] Flutter SDK 3.44.1 stable instalado em `C:\dev\flutter` (PATH do usuário) com web habilitado.
- [x] venv Python em `backend/.venv` com dependências do `requirements.txt`.

### Etapa A — Backend: fundação
- [x] `core/`: config via `DATABASE_URL` (SQLite default, portável p/ PostgreSQL), sessão SQLAlchemy, JWT (PyJWT) + bcrypt.
- [x] Models SQLAlchemy 2.0: Student, Gym, Plan, Subscription, CheckIn (snapshots de tier e valor), Payout.
- [x] Migration inicial Alembic aplicada.
- [x] Auth: `POST /auth/register/student`, `POST /auth/login` único com role no JWT.
- [x] `seed.py` idempotente: 7 planos, 10 academias (Campinas/Americana), 15 estudantes, ~200 check-ins em 2 meses, payouts (mês retrasado pago, mês passado pendente) + credenciais impressas.
- [x] **Checkpoint:** logins estudante/academia/senha errada validados via curl (tokens e roles corretos).

### Etapa B — Backend: domínio
- [x] `GET /plans`; `GET /gyms` (filtros), `GET /gyms/{id}`, `PUT /gyms/{id}` (só a própria academia).
- [x] `POST /subscriptions`, `GET /students/me`, `GET /students/me/subscription`, `PUT /subscriptions/{id}`.
- [x] `POST /checkins` (`services/checkin_service.py`: tier ≥ tier mínimo, anti-fraude 3h, snapshot do repasse), `GET /students/me/checkins`, `GET /gyms/me/checkins`.
- [x] **Checkpoint:** 201 válido; 409 anti-fraude; 403 tier insuficiente com mensagem clara — todos demonstrados via curl.

### Etapa C — Backend: financeiro
- [x] `services/payout_service.py`: repasse do mês = Σ snapshots; agregações portáveis SQLite/PostgreSQL.
- [x] `GET /gyms/me/dashboard`, `/payouts`, `/payouts/{mes}`, `/payouts/{mes}/export` (CSV padrão BR com BOM), `/students` (gestão de alunos). CORS para localhost.
- [x] **Checkpoint:** valores conferidos contra o seed (ex.: Campus Fit jun = 5×8 = R$ 40; mai = 17×8 = R$ 136; abr = 9×8 = R$ 72 pago).

### Etapa D — shared_models + design system + app mobile
- [x] Package `shared_models`: DTOs Dart, `ApiClient` (dio + interceptor JWT), formatadores BR, design system completo (`UniHubColors/Spacing/Radius/Styles` + `UniHubTheme`). 3 testes unitários passando.
- [x] App Flutter (Riverpod + go_router, camadas data/domain/presentation): login/cadastro, Home (plano, resumo do mês, academias próximas, CTA), Explorar (busca + filtro de modalidade + badges de acesso + detalhe), Check-in (lista + simulação de QR + confirmação + sucesso + bloqueios), Perfil (carteirinha digital, histórico, troca de plano, sair).
- [x] `flutter analyze` limpo.
- [x] **Checkpoint visual (Chrome):** login → Home com dados reais → fluxo de check-in com sheet de confirmação → tela de sucesso. Tela de detalhe mostra estado bloqueado ("disponível a partir do Plano X").

### Etapa E — Painel web da academia
- [x] Login (role gym), shell com navegação lateral.
- [x] Dashboard: 4 métricas (receita em destaque laranja), gráfico de check-ins/dia (30 dias) e por faixa de horário (fl_chart).
- [x] Alunos: tabela com busca e ordenação por coluna.
- [x] Financeiro: extrato do mês corrente, histórico de payouts (pendente/pago), detalhamento por check-in, export CSV (download verificado: `extrato-unihub-2026-06.csv`).
- [x] Configurações: edição dos dados da academia + tier mínimo.
- [x] `flutter analyze` limpo.
- [x] **Checkpoint E2E (provado com screenshots):** check-in feito no app às 14:25 → dashboard da academia atualizou de 5 → 6 check-ins, 6 alunos únicos e R$ 40,00 → R$ 48,00.

### Etapa F — Encerramento
- [x] `README.md` com passo a passo (backend, mobile, web), credenciais e roteiro de demo.
- [x] Critérios de aceitação da spec verificados (ver abaixo).

## Critérios de aceitação (seção 13 da spec)

- [x] Login como estudante no app: plano e academias visíveis.
- [x] Check-in válido; bloqueio por tier comprovado (403 via API com Pedro/Plano 1 no CrossBox tier 5 + UI preventiva com badge e detalhe sem botão de check-in).
- [x] Check-in aparece no painel da academia.
- [x] Dashboard com métricas e gráficos coerentes com o seed.
- [x] Financeiro calcula repasse (check-ins × valor) e lista detalhamento.
- [x] Extrato exportado em CSV (conferido em disco, padrão BR).
- [x] Backend, mobile e web sobem seguindo só o README.

## Como rodar

Ver `README.md`. Resumo: backend (`alembic upgrade head` → `python seed.py` → `uvicorn app.main:app --port 8000`), depois `flutter run -d chrome` em `mobile/` e `web_admin/`.

Credenciais: estudante `joao.silva@dac.unicamp.br` / `senha123` — academia `contato@campusfit.com.br` / `academia123`.
