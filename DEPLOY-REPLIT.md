# Deploy Betooth no Replit — Guia Ultra Simples

## Passo 1 — Abra o Replit e importe o projeto

1. Acesse **[replit.com](https://replit.com)** e faça login (ou crie conta grátis)
2. Clique em **"+ Create Repl"**
3. Selecione a aba **"Import from GitHub"**
4. Cole a URL do repositório:
   ```
   https://github.com/betosouzabb-maker/Betooth
   ```
5. Clique em **"Import from GitHub"**

---

## Passo 2 — Adicione os serviços (PostgreSQL + Redis)

No painel esquerdo do Replit:

1. Clique em **"Tools"** → **"Database"**
   - Selecione **PostgreSQL** → clique em **"Create"**
   - O Replit cria o banco e define `DATABASE_URL` automaticamente

2. Clique em **"Tools"** → **"Database"**
   - Selecione **Redis** → clique em **"Create"**
   - O Replit define `REDIS_URL` automaticamente

---

## Passo 3 — Configure as variáveis de ambiente

No painel esquerdo, clique em **"Secrets"** (cadeado) e adicione:

| Variável | Valor | Obrigatório |
|---|---|---|
| `JWT_ACCESS_SECRET` | string aleatória longa (ex: `openssl rand -hex 48`) | **Sim** |
| `JWT_REFRESH_SECRET` | string aleatória longa (diferente da anterior) | **Sim** |
| `S3_BUCKET` | nome do seu bucket S3 ou R2 | **Sim** |
| `S3_ACCESS_KEY_ID` | chave AWS/R2 | **Sim** |
| `S3_SECRET_ACCESS_KEY` | secret AWS/R2 | **Sim** |
| `S3_ENDPOINT` | apenas para Cloudflare R2 | Opcional |
| `MP_ACCESS_TOKEN` | token Mercado Pago producao | Opcional |
| `MP_WEBHOOK_SECRET` | secret do webhook MP | Opcional |
| `CORS_ORIGIN` | URL do seu app Flutter/frontend | Opcional |
| `ADMIN_MASTER_PASSWORD` | senha do admin master | Opcional |

> **`DATABASE_URL` e `REDIS_URL` NAO precisam ser adicionadas** — o Replit preenche automaticamente.

Gerar segredos JWT (copie e rode no terminal do Replit):
```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

---

## Passo 4 — Primeiro setup (apenas na primeira vez)

No terminal do Replit, rode:
```bash
bash setup-replit.sh
```

Isso vai:
- Instalar dependências (`npm ci`)
- Gerar o Prisma Client
- Rodar as migrations (`prisma migrate deploy`)
- Rodar o seed inicial

---

## Passo 5 — Clique em Run

Clique no botao verde **"Run"** no topo da tela.

O backend vai iniciar em:
```
https://<seu-repl-nome>.<seu-usuario>.repl.co
```

Teste o endpoint de saúde:
```
GET https://<seu-repl-nome>.<seu-usuario>.repl.co/api/v1/health
```

---

## Passo 6 — Deploy em producao (1 clique)

1. No painel esquerdo, clique em **"Deployments"**
2. Selecione **"Autoscale"** ou **"Reserved VM"**
3. Clique em **"Deploy"**
4. Aguarde ~2 minutos

Sua URL de producao ficara no formato:
```
https://<seu-repl-nome>.<seu-usuario>.repl.co
```

---

## Resumo das variaveis automaticas do Replit

| Variavel | Definida por |
|---|---|
| `DATABASE_URL` | Replit PostgreSQL (automatico) |
| `REDIS_URL` | Replit Redis (automatico) |
| `PORT` | Replit (automatico, usa 3333 por padrao) |

---

## Avisos

- **Plano gratuito**: o Repl "dorme" apos inatividade — primeira requisicao pode demorar ~10s
- **Para producao real**: use o plano **Replit Core** (~$25/mes) ou **Autoscale Deployments**
- **Banco de dados**: o PostgreSQL do Replit e persistente mesmo no plano gratuito
- **Redis**: disponivel via modulo do Replit ou use um Redis externo (ex: Upstash — plano gratuito)

---

## Problemas comuns

### Erro: `DATABASE_URL not set`
→ Certifique-se de ter criado o banco PostgreSQL em Tools → Database

### Erro: `Invalid environment variables`
→ Adicione `JWT_ACCESS_SECRET` e `JWT_REFRESH_SECRET` em Secrets

### Porta nao abre
→ O `.replit` já configura a porta 3333 → 80. Nao altere.

### Prisma: `Migration failed`
→ Rode `bash setup-replit.sh` novamente no terminal
