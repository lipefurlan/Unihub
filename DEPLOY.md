# Deploy do MVP UniHub — felipefurlan.com.br

Arquitetura: **Netlify** (frontends, grátis — você já usa) + **Railway** (API + PostgreSQL, ~US$ 5/mês).

```
app.felipefurlan.com.br     → Netlify  (app do estudante, PWA)
painel.felipefurlan.com.br  → Netlify  (painel academia + admin)
api.felipefurlan.com.br     → Railway  (FastAPI + PostgreSQL)
```

---

## Parte 1 — API no Railway (~15 min)

1. Crie a conta em **railway.app** (login com GitHub é o mais fácil) e assine o plano **Hobby** (US$ 5/mês).
2. **New Project → Deploy from GitHub repo**:
   - Suba este projeto para um repositório no seu GitHub antes (pode ser privado).
   - Selecione o repositório e, em *Settings → Root Directory*, informe **`backend`** (o `Dockerfile` que está lá faz o resto: migrations + seed na primeira subida + uvicorn).
3. No mesmo projeto: **+ New → Database → PostgreSQL**. O Railway cria o banco.
4. No serviço da API, aba **Variables**:
   - `DATABASE_URL` → clique em *Add Reference* e aponte para a variável `DATABASE_URL` do PostgreSQL criado;
   - `SECRET_KEY` → invente uma chave longa e aleatória (ex.: 64 caracteres — pode gerar em um gerenciador de senhas). **Não use a default do código.**
5. Aba **Settings → Networking → Custom Domain**: adicione `api.felipefurlan.com.br`. O Railway mostra um **CNAME** (algo como `xxxx.up.railway.app`).
6. No **Netlify → Domains → felipefurlan.com.br → DNS records**: crie um registro **CNAME** com nome `api` apontando para o valor que o Railway mostrou. Aguarde alguns minutos (o HTTPS é automático).
7. Teste: abra `https://api.felipefurlan.com.br/docs` — o Swagger deve carregar. O banco já estará populado com os dados de demonstração (o seed roda sozinho na primeira subida).

## Parte 2 — App e painel no Netlify (~10 min)

Os builds prontos estão em `deploy/app/` e `deploy/painel/` (já apontam para `https://api.felipefurlan.com.br` e incluem o `_redirects`).

Para cada um:

1. **Netlify → Add new site → Deploy manually** e **arraste a pasta** (`deploy/app` primeiro, depois `deploy/painel` em outro site).
2. No site criado: **Domain settings → Add custom domain** → `app.felipefurlan.com.br` (e `painel.felipefurlan.com.br` no outro). Como o DNS já é do Netlify, ele configura sozinho, com HTTPS.

Pronto. Compartilhe com os orientadores:

| URL | Login de teste |
|---|---|
| `https://app.felipefurlan.com.br` | `joao.silva@dac.unicamp.br` / `senha123` (ou "Cadastre-se") |
| `https://painel.felipefurlan.com.br` | academia: `contato@campusfit.com.br` / `academia123` · admin: `admin@unihub.com.br` / `admin123` |

No celular: abrir a URL no navegador → menu **Compartilhar → Adicionar à Tela de Início** = vira um "app" com ícone.

---

## Para atualizar depois de mudanças no código

- **API**: `git push` no repositório → o Railway redeploya sozinho.
- **Frontends**: rode na raiz do projeto e arraste as pastas de novo no Netlify (*Deploys → drag & drop*):
  ```powershell
  cd mobile;    flutter build web --release --dart-define=UNIHUB_API=https://api.felipefurlan.com.br
  cd ..\web_admin; flutter build web --release --dart-define=UNIHUB_API=https://api.felipefurlan.com.br
  ```
  (e copie `build/web` para `deploy/app` e `deploy/painel`, mantendo o arquivo `_redirects`)

## Login com Google e "esqueci minha senha" (configuração única)

Os dois recursos já estão no código e ficam desligados até você configurar. Sem configuração, o botão do Google não aparece e o link de redefinição de senha só sai no log da API.

### Login com Google (grátis)

1. Entre em **console.cloud.google.com**, crie um projeto (ex.: `UniHub`).
2. **APIs e serviços → Tela de permissão OAuth**: tipo **Externo**, nome `UniHub`, e-mail de suporte, domínio `felipefurlan.com.br`. Publique o app (enquanto estiver "em teste", só os e-mails que você listar conseguem entrar).
3. **APIs e serviços → Credenciais → Criar credenciais → ID do cliente OAuth**, tipo **Aplicativo da Web**. Em **Origens JavaScript autorizadas**, adicione:
   - `https://app.felipefurlan.com.br`
   - `https://painel.felipefurlan.com.br`
   - `http://localhost:5000` e `http://localhost:5001` (para testar local)
4. Copie o **ID do cliente** (termina em `.apps.googleusercontent.com`) e coloque em dois lugares:
   - **Railway → serviço da API → Variables**: `GOOGLE_CLIENT_ID`
   - **GitHub → Settings → Secrets and variables → Actions → aba Variables**: `GOOGLE_CLIENT_ID`
5. Rode o deploy dos frontends de novo (aba **Actions → Deploy web no Netlify → Run workflow**).

No app do estudante, o Google cria a conta no primeiro acesso, desde que o e-mail seja de uma IES conveniada. No painel, ele só entra em conta de academia/admin que já existe.

### E-mail de redefinição de senha (Resend, grátis até 3.000 e-mails/mês)

1. Crie a conta em **resend.com** → **Domains → Add domain** → `felipefurlan.com.br`.
2. O Resend mostra 3 ou 4 registros DNS (TXT e MX). Crie cada um no **Netlify → Domains → felipefurlan.com.br → DNS records** e clique em **Verify** no Resend.
3. **API Keys → Create API key** (permissão "Sending access").
4. **Railway → Variables** da API:
   - `RESEND_API_KEY` = a chave criada
   - `EMAIL_FROM` = `UniHub <nao-responda@felipefurlan.com.br>` (opcional, este já é o padrão)
   - `STUDENT_APP_URL` = `https://app.felipefurlan.com.br`
   - `PANEL_APP_URL` = `https://painel.felipefurlan.com.br`

O link vale 60 minutos e só pode ser usado uma vez. Por segurança, a tela sempre diz "se houver uma conta, enviamos o link", exista ou não o e-mail.

## Regras do plano de negócio (IES conveniada, preço e teto de visitas)

- **Só alunos de IES conveniada se cadastram**: o domínio do e-mail precisa estar na tabela `universities`. O seed cria FACAMP, Unicamp, PUC-Campinas, FATEC Americana, FAM, ESAMC e Mackenzie.
- **Preço**: plano de R$ 130; o aluno paga R$ 130 menos o subsídio da IES (R$ 10 no seed = R$ 120).
- **IES**: R$ 3 mil por mês de taxa fixa + R$ 15 por aluno que assina + o subsídio. Entra na "Receita das IES" da visão geral do admin.
- **Academias**: R$ 8 por visita, pagas só as 10 primeiras visitas do aluno no mês (somando todas as academias). Da 11ª em diante, o check-in funciona, mas aparece como "Não remunerada" no extrato da academia. O teto muda pela variável `MAX_PAID_CHECKINS_PER_MONTH` da API.
- Os valores do seed ficam no topo de `backend/seed.py` (`PLAN_PRICE`, `PAYOUT_PER_VISIT`, `IES_*`).

**Depois de publicar esta versão, resete a demo** para os dados novos entrarem (o seed só roda com o banco vazio): no Railway, abra o PostgreSQL → **Data** → apague as tabelas (ou crie um banco novo e troque a referência de `DATABASE_URL`) e faça **Redeploy** da API. A migration já cadastra as 7 IES e liga os alunos existentes a elas, então o cadastro funciona mesmo sem resetar; o que só aparece depois do reset é o plano único de R$ 130, o repasse de R$ 8 em todas as academias e os check-ins de demonstração do João perto do teto.

## Fase 2 e 3: portal da faculdade, checkout, QR de entrada e app do aluno

Depois de publicar esta versão, **resete a demo de novo** (mesmo passo acima: apague as tabelas no PostgreSQL do Railway e faça Redeploy). As migrations criam as colunas novas sozinhas, mas o login da FACAMP, a meta e a cidade natal do João, as favoritas e os horários dos check-ins só vêm do seed.

- **Login da faculdade**: `programa@facamp.edu.br` / `facamp123` no painel (botão "Faculdade" na tela de login).
- **Fuso horário**: o Dockerfile agora fixa `TZ=America/Sao_Paulo`, então check-ins, semanas da meta e virada do mês seguem o horário de Brasília.
- **Localização**: o app pede a localização ao navegador. Só funciona em HTTPS (o Netlify já é). Se o aluno negar, as distâncias usam o campus.
- **Checkout**: é simulado. Nenhum dado de cartão sai do navegador e nada é cobrado.
- Nada novo para configurar no Railway ou no Netlify.

## Desafios entre faculdades e cursos

Depois de publicar esta versão, **resete a demo de novo** (mesmo passo acima). A migration cria a tabela de desafios e o campo de curso, mas os cursos dos alunos, os 5 alunos novos da FACAMP e os 3 desafios de exemplo só vêm do seed.

- **Placar público**: o link é `https://painel.felipefurlan.com.br/#/placar/<código>`. O painel copia o link pronto no botão **Copiar link**. Não pede login, então serve para a TV do campus ou para o grupo da turma.
- Nada novo para configurar no Railway ou no Netlify.

## Limitações conhecidas do MVP (ok para teste com orientadores)

- **Fotos das academias**: o disco do Railway é efêmero — fotos enviadas pelo admin somem em um redeploy. Para produção real, migrar para Cloudflare R2/S3 (a API não muda).
- Não há código de verificação por e-mail no cadastro: a regra é só o domínio da IES. Quem entra pelo Google tem o e-mail verificado pelo próprio Google.
- O seed só roda quando o banco está vazio; para resetar a demo, apague os dados do PostgreSQL no Railway e redeploye.
- CORS já está liberado para `*.felipefurlan.com.br` (configurável pela env `CORS_ORIGIN_REGEX`).
