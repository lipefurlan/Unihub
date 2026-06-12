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

## Limitações conhecidas do MVP (ok para teste com orientadores)

- **Fotos das academias**: o disco do Railway é efêmero — fotos enviadas pelo admin somem em um redeploy. Para produção real, migrar para Cloudflare R2/S3 (a API não muda).
- Sem recuperação de senha/verificação de e-mail (você reseta na mão se alguém esquecer: re-rodar seed ou atualizar via banco).
- O seed só roda quando o banco está vazio; para resetar a demo, apague os dados do PostgreSQL no Railway e redeploye.
- CORS já está liberado para `*.felipefurlan.com.br` (configurável pela env `CORS_ORIGIN_REGEX`).
