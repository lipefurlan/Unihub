# UniHub — Plano de melhorias (backlog)

Itens decididos durante o desenvolvimento do MVP, em ordem sugerida de prioridade.

## Autenticação e contas

- [ ] **Login com Google (OAuth)** — entrar no app/painel com a conta Google, sem criar senha.
  Caminho: Google Cloud Console (OAuth Client ID) + `google_sign_in` no Flutter + endpoint
  `POST /auth/google` no backend validando o token e criando/vinculando a conta.
- [ ] **"Esqueci minha senha"** — fluxo por e-mail com link/código de redefinição
  (exige um serviço de envio de e-mail, ex.: Resend/SendGrid, com domínio felipefurlan.com.br).
- [ ] **Redefinição de senha pelo admin** — botão no painel (Estudantes/Academias) que gera uma
  senha temporária, para suporte manual enquanto não há fluxo por e-mail.
- [ ] **E-mail universitário verificado** — allowlist de domínios por universidade
  (ex.: dac.unicamp.br, puccampinas.edu.br) gerenciada pelo admin + código de
  verificação enviado por e-mail. Garante que só estudante real assina o plano.
- [ ] **Rate limiting no login** — bloquear tentativas repetidas de senha (força bruta).
  Barato (ex.: slowapi) e alto impacto de segurança.
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

- [ ] **Testes automatizados no backend (pytest)** — regras de tier, anti-fraude e cálculo
  de repasse cobertas por testes.
- [ ] **CI no GitHub Actions** — a cada push: testes do backend + `flutter analyze` dos
  três projetos.

## Plataforma

- [ ] Fotos das academias em storage permanente (Cloudflare R2/S3) — hoje o disco do Railway
  é efêmero e as fotos enviadas pelo admin se perdem em redeploy.
- [ ] Pagamentos reais das assinaturas (PIX/cartão — ex.: Mercado Pago, Stripe, Asaas).
- [ ] Título das abas dos sites web ("UniHub" no lugar de "unihub_mobile"/"unihub_web_admin").
- [ ] Monitoramento e alertas de erro (ex.: Sentry) + backups automáticos do PostgreSQL.
- [ ] Termos de uso e política de privacidade (LGPD) — obrigatórios para as lojas.

## Segurança (estado atual — referência)

- Senhas: hash **bcrypt** com sal (irreversível; nem o admin vê as senhas) ✅
- Tokens JWT assinados com `SECRET_KEY` via variável de ambiente ✅
- Cláusulas comerciais (repasse/tier) editáveis apenas pelo admin ✅
