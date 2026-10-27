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
- [x] **Redefinição de senha pelo admin** — feito: botão de chave em Estudantes e Academias gera
  uma senha temporária de 8 caracteres, mostrada uma única vez.
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

- [x] Localização real (geolocator), com o campus quando o aluno não libera.
- [x] QR + código de entrada por visita, validado pela recepção no painel ("Validar entrada").
  Falta: leitura pela câmera no painel (hoje a recepção digita ou usa leitor USB de QR).
- [ ] Notificações push (lembrete de treino, confirmação de check-in, avisos da operação).
- [ ] Publicação: Google Play (US$ 25 únicos, .aab assinado) e App Store
  (US$ 99/ano + build macOS via Codemagic/TestFlight).

## Painel web

- [x] **Versão mobile/responsiva do painel** — feito (drawer, métricas em 2 colunas, tabelas com rolagem).
- [x] **Portal da faculdade (IES)** — feito: login da IES, adesão, uso, fatura do mês e lista de alunos.
- [ ] **Relatório mensal automático por e-mail** para a academia (extrato PDF/CSV no
  fechamento do mês).
- [ ] **Métricas de negócio no admin** — evolução de assinantes, churn, MRR de assinaturas
  vs. repasses mês a mês.

## App do aluno

- [x] Meta semanal com sequência de semanas e resumo do mês.
- [x] Pausar e retomar o plano (férias).
- [x] Cidade natal e filtro por cidade no Explorar.
- [x] Academias favoritas e horário mais tranquilo de cada academia.
- [x] Avaliar a visita (1 a 5 estrelas); nota média nos cards e no painel da academia.
- [x] Perfil com conquistas (selos) e card da sequência de semanas.
- [x] Desafios configuráveis: entre faculdades (operação) ou entre cursos de uma faculdade (operação ou a própria faculdade), pontuando check-ins por aluno ou % da turma treinando toda semana.
- [x] Painel "Desafios" com ranking, evolução semanal, histórico de campeões e placar público para TV e grupo da turma.
- [x] Curso no cadastro e no perfil do aluno; o app mostra os desafios do aluno e quanto ele somou.
- [ ] Prêmios e notificações dos desafios (push quando o curso cai de posição, aviso de último dia).
- [ ] Indicador de bem-estar por curso para a coordenação (frequência ao longo do semestre).
- [x] Explorar com carrosséis "Perto de você" e "Bombando nesta semana" e troca de localização.
- [ ] Indique um amigo (código e link de convite).
- [ ] Reserva de aulas (precisa da agenda das academias).

## Qualidade (valor de TCC)

- [x] **Testes automatizados no backend (pytest)** — começados: auth, IES conveniada, subsídio e
  teto de visitas pagas, portal da IES, senha temporária, meta, favoritas, cidade, horário vazio,
  pausa e código de entrada (`backend/tests`, 22 testes). Faltam tier e anti-fraude.
- [x] **CI no GitHub Actions** — testes do backend a cada push. Falta `flutter analyze`.

## Plataforma

- [ ] Fotos das academias em storage permanente (Cloudflare R2/S3) — hoje o disco do Railway
  é efêmero e as fotos enviadas pelo admin se perdem em redeploy.
- [ ] Pagamentos reais das assinaturas (PIX/cartão — ex.: Asaas ou Mercado Pago). O checkout
  simulado já existe no app; falta trocar a simulação pela chamada ao gateway e criar a
  assinatura só no webhook de pagamento confirmado.
- [x] Título das abas e nome ao instalar no celular ("UniHub" / "UniHub Painel").
- [ ] Monitoramento e alertas de erro (ex.: Sentry) + backups automáticos do PostgreSQL.
- [ ] Termos de uso e política de privacidade (LGPD) — obrigatórios para as lojas.

## Segurança (estado atual — referência)

- Senhas: hash **bcrypt** com sal (irreversível; nem o admin vê as senhas) ✅
- Tokens JWT assinados com `SECRET_KEY` via variável de ambiente ✅
- Cláusulas comerciais (repasse/tier) editáveis apenas pelo admin ✅
