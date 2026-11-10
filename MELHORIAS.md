# UniHub — Plano de melhorias (backlog)

Itens decididos durante o desenvolvimento do MVP, em ordem sugerida de prioridade.

## Autenticação e contas

- [x] **Login com Google (OAuth)** — feito: botão do Google no app e no painel (versão web),
  `POST /auth/google` valida o ID token. Configuração em DEPLOY.md.
  Caminho: Google Cloud Console (OAuth Client ID) + `google_sign_in` no Flutter + endpoint
  `POST /auth/google` no backend validando o token e criando/vinculando a conta.
- [x] **"Esqueci minha senha"** — feito: link por e-mail (Resend), válido por 60 min e de uso único.
  Antes: fluxo por e-mail com link/código de redefinição
  (exige um serviço de envio de e-mail, ex.: Resend/SendGrid, com domínio felipefurlan.com.br).
- [ ] **Redefinição de senha pelo admin** — botão no painel (Estudantes/Academias) que gera uma
  senha temporária, para suporte manual enquanto não há fluxo por e-mail.
- [x] **Allowlist de domínios por IES conveniada** — feito (tabela `universities`). Falta o
  código de verificação por e-mail no cadastro com senha.
  Antes: allowlist de domínios por universidade
  (ex.: dac.unicamp.br, puccampinas.edu.br) gerenciada pelo admin + código de
  verificação enviado por e-mail. Garante que só estudante real assina o plano.
- [x] **Rate limiting no login** — feito (slowapi): 10 tentativas/min no login e
  5/min no cadastro, por IP, com resposta 429 em PT-BR. IP real preservado atrás
  do proxy do Railway (`--proxy-headers`).
- [ ] Refresh token / expiração mais curta do JWT (hoje: 24h, sem renovação).

## App nativo (lojas)

- [ ] GPS real no lugar da localização mockada (campus fixo).
- [ ] Leitura de QR code real na recepção da academia (camera + QR por academia).
- [ ] Notificações push (lembrete de treino, confirmação de check-in, avisos da operação).
- [ ] Publicação: Google Play (US$ 25 únicos, .aab assinado) e App Store
  (US$ 99/ano + build macOS via Codemagic/TestFlight).

## Painel web

- [ ] **Versão mobile/responsiva do painel** — hoje o layout é de desktop (menu lateral fixo
  e tabelas largas). Adaptar para celular: menu lateral vira drawer/menu inferior, métricas
  empilham, tabelas viram cards ou ganham rolagem horizontal. Vale para academia e admin —
  o dono da academia vai querer conferir os repasses pelo celular.
- [ ] **QR code real por academia** — o painel exibe/imprime o QR da academia (recepção);
  o app escaneia para fazer o check-in. Fecha o ciclo anti-fraude de presença física.
- [ ] **Relatório mensal automático por e-mail** para a academia (extrato PDF/CSV no
  fechamento do mês).
- [ ] **Métricas de negócio no admin** — evolução de assinantes, churn, MRR de assinaturas
  vs. repasses mês a mês.

## Qualidade (valor de TCC)

- [x] **Testes automatizados no backend (pytest)** — começados: auth, IES conveniada, subsídio e
  teto de visitas pagas (`backend/tests`). Faltam tier e anti-fraude.
- [ ] **CI no GitHub Actions** — a cada push: testes do backend + `flutter analyze` dos
  três projetos.

## Plataforma

- [ ] Fotos das academias em storage permanente (Cloudflare R2/S3) — hoje o disco do Railway
  é efêmero e as fotos enviadas pelo admin se perdem em redeploy.
- [ ] Pagamentos reais das assinaturas (PIX/cartão — ex.: Mercado Pago, Stripe, Asaas).
- [x] Título das abas e nome ao instalar no celular ("UniHub" / "UniHub Painel").
- [ ] Monitoramento e alertas de erro (ex.: Sentry) + backups automáticos do PostgreSQL.
- [ ] Termos de uso e política de privacidade (LGPD) — obrigatórios para as lojas.

## Segurança (estado atual — referência)

- Senhas: hash **bcrypt** com sal (irreversível; nem o admin vê as senhas) ✅
- Tokens JWT assinados com `SECRET_KEY` via variável de ambiente ✅
- Cláusulas comerciais (repasse/tier) editáveis apenas pelo admin ✅
