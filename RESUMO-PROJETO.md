# UniHub — Resumo técnico do POC (para consulta sobre hospedagem, custos e publicação nas lojas)

## O produto

**UniHub** é uma plataforma agregadora de bem-estar para universitários brasileiros — um "Wellhub para estudante". Modelo **B2B2C com repasse por check-in**:

- O **estudante** assina um plano mensal (Plano 1 a 7, de ~R$ 80 a ~R$ 250, tiers crescentes de acesso) e faz check-in em academias parceiras perto do campus.
- A **academia parceira** recebe um valor por check-in efetivado (R$ 8–20, definido por academia), preenchendo capacidade ociosa sem custo fixo.
- Regras de negócio centrais: check-in só é permitido se o tier do plano do aluno ≥ tier mínimo da academia; cada check-in grava um snapshot do valor de repasse vigente; o repasse mensal da academia = soma dos snapshots do mês (status pendente → pago); anti-fraude de 1 check-in por aluno/academia a cada 3h.

É a base de um TCC. Hoje é um POC funcional completo rodando localmente, sem pagamentos reais e sem deploy.

## O que existe hoje (monorepo, ~tudo funcionando localmente)

```
unihub/
├── backend/        FastAPI (Python 3.11) + SQLAlchemy 2.0 + Pydantic v2 + Alembic
│                   SQLite local, mas 100% portável p/ PostgreSQL via DATABASE_URL
│                   Auth JWT com roles (student | gym), bcrypt para senhas
├── mobile/         Flutter 3.44 — app do estudante (targets iOS + Android + web criados)
│                   Riverpod, go_router, dio; camadas data/domain/presentation
├── web_admin/      Flutter Web — painel da academia (fl_chart para gráficos)
└── shared_models/  Package Dart compartilhado: DTOs, cliente HTTP (dio), design system
```

### API (FastAPI) — endpoints principais
- Auth: `POST /auth/register/student`, `POST /auth/login` (JWT com role)
- Catálogo: `GET /plans`, `GET /gyms` (filtros), `GET /gyms/{id}`, `PUT /gyms/{id}` (academia edita os próprios dados)
- Assinaturas: `POST /subscriptions`, `GET /students/me/subscription`, `PUT /subscriptions/{id}` (troca de plano)
- Check-ins: `POST /checkins` (valida tier + anti-fraude + snapshot), `GET /students/me/checkins`, `GET /gyms/me/checkins`
- Painel financeiro: `GET /gyms/me/dashboard` (métricas + séries p/ gráficos), `GET /gyms/me/payouts`, `GET /gyms/me/payouts/{mes}` (detalhamento), `GET /gyms/me/payouts/{mes}/export` (CSV)
- OpenAPI/Swagger habilitado; CORS configurado p/ dev local

### Modelo de dados (6 entidades)
Student, Gym (com lat/lng, modalidades, tier mínimo, valor de repasse), Plan (7 tiers), Subscription, CheckIn (com snapshots de tier e valor), Payout (consolidado mensal por academia, pendente/pago). Migrations com Alembic.

### App do estudante (Flutter)
Login/cadastro JWT; 4 abas: Home (plano atual, resumo do mês, academias próximas com distância via haversine — geolocalização mockada no campus), Explorar (busca, filtro por modalidade, badge de acesso por tier, detalhe da academia), Check-in (seleção/simulação de QR → confirmação → tela de sucesso; bloqueios com mensagem da API), Perfil (carteirinha digital, histórico, troca de plano). UI inteira em PT-BR.

### Painel da academia (Flutter Web)
Dashboard (check-ins do mês, alunos únicos, receita estimada de repasse, comparativo com mês anterior, gráfico de check-ins/dia e por faixa de horário), gestão de alunos (tabela com busca/ordenação), financeiro (extrato do mês, histórico de payouts, detalhamento por check-in, export CSV padrão BR), configurações (dados da academia + tier mínimo + valor de repasse).

### Design system
Compartilhado entre app e painel via package: branco + cinza-claro, laranja #FF5A1F como única cor de acento, tipografia Inter (google_fonts), ícones Lucide, raios ≤ 8px, sem gradientes/sombras. Tokens centralizados (cores, espaçamento, raio, tema Material 3).

### Estado de validação
Tudo testado ponta a ponta localmente: seed com 7 planos, 10 academias (região de Campinas/Americana), 15 estudantes e ~200 check-ins em 2 meses; ciclo completo provado (check-in no app → aparece no painel → financeiro recalcula → CSV exporta). `flutter analyze` limpo; testes unitários no package compartilhado.

## O que AINDA NÃO existe (relevante para produção)

- Nenhum deploy: tudo roda em localhost (uvicorn + flutter run)
- Banco: SQLite local (migração p/ PostgreSQL é só trocar `DATABASE_URL`)
- Sem pagamentos reais (troca de plano só altera registro; sem gateway/PIX/cartão)
- Sem builds assinados iOS/Android (os targets existem, mas nunca foi gerado .ipa/.aab; desenvolvimento foi 100% em Windows, sem Mac)
- Sem push notifications, sem analytics/crash reporting, sem CI/CD
- Geolocalização mockada (posição fixa no campus); QR code de check-in é simulado
- JWT com secret de dev; sem refresh token; sem recuperação de senha; sem verificação de e-mail
- Sem termos de uso/política de privacidade (necessários para as lojas)
- Painel da academia é Flutter Web (precisa de hospedagem estática + a API pública)

## Contexto do desenvolvedor

- Desenvolvedor solo, estudante (projeto de TCC que pode virar produto real)
- Máquina de desenvolvimento: Windows 11 (sem Mac físico)
- Orçamento limitado — interessa a rota mais barata viável no Brasil

## O que quero entender (perguntas que vou fazer)

1. **Hospedagem do backend + PostgreSQL**: opções e custos (ex.: Railway, Render, Fly.io, VPS, AWS/GCP free tier), o que faz sentido para um MVP com poucos usuários no Brasil.
2. **Hospedagem do painel web** (build estático Flutter Web) e domínio/HTTPS.
3. **Publicação nas lojas**: passo a passo e custos — Google Play (conta US$ 25 única, .aab assinado) e App Store (US$ 99/ano + necessidade de macOS/Xcode para build — alternativas tipo Codemagic/GitHub Actions com runner macOS, TestFlight).
4. **O que as lojas exigem** além do build: política de privacidade, LGPD, contas de teste para revisão, screenshots, classificação etária etc.
5. Estimativa de **custo mensal total** para manter um MVP no ar (infra + contas de desenvolvedor + eventuais serviços).
6. O que priorizar tecnicamente antes do lançamento (pagamentos, push, refresh token, monitoramento...).
