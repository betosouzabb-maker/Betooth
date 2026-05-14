# Deploy do Backend Betooth no Railway

## Pré-requisitos
- Conta no [Railway.app](https://railway.app) (login com GitHub)
- Repositório `betosouzabb-maker/Betooth` conectado ao Railway
- Acesso ao painel do Mercado Pago (para configurar webhook)

---

## 1. Criar o projeto no Railway

1. Acesse https://railway.app/new
2. Clique em **"Deploy from GitHub repo"**
3. Selecione `betosouzabb-maker/Betooth`
4. Na tela de configuração do serviço:
   - **Root Directory:** `/backend`
   - Railway detecta Node.js automaticamente via `nixpacks.toml`

---

## 2. Adicionar PostgreSQL

1. No dashboard do projeto, clique em **"+ New"** → **"Database"** → **"Add PostgreSQL"**
2. Railway cria o banco e disponibiliza `DATABASE_URL` automaticamente

---

## 3. Adicionar Redis

1. Clique em **"+ New"** → **"Database"** → **"Add Redis"**
2. Railway cria o Redis e disponibiliza `REDIS_URL` automaticamente

---

## 4. Configurar variáveis de ambiente

No serviço do backend, vá em **Variables** e adicione:

```
NODE_ENV=production
APP_URL=https://<URL-GERADA-PELO-RAILWAY>
DATABASE_URL=${{Postgres.DATABASE_URL}}
DIRECT_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}

JWT_ACCESS_SECRET=fa5e4b2bd1fdb10d3848b0ffa12bf1dce15670850a4d6018a0650842697d28e47ce2c90ebfa6af50949e59e42b4a93a2
JWT_REFRESH_SECRET=c2c56e70889c868ecf2ade21aa0c37805377e2f66bdbda21a954571e17c899be3ef30f9cadac4905e3b3caaf27bad527
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

ADMIN_MASTER_PASSWORD=YGTAKVFGHNPPEKBFHLRTAXMTAOISRTSJ

MP_ACCESS_TOKEN=APP_USR-3763087401361604-051110-1b7273909c73a1d5bf5724acf92e54b9-246148546
MP_WEBHOOK_SECRET=<configurar-depois-no-painel-MP>
MP_PLAN_PRICE_CENTS=999
MP_PLAN_LABEL=Betooth VIP Mensal

FREE_MONTHLY_DOWNLOAD_LIMIT=5
VIP_CACHE_TTL_SECONDS=300

S3_REGION=sa-east-1
S3_BUCKET=<seu-bucket>
S3_ACCESS_KEY_ID=<sua-key>
S3_SECRET_ACCESS_KEY=<seu-secret>

CORS_ORIGIN=*
LOG_LEVEL=info
QUEUE_PREFIX=betooth
```

> **Nota:** `DATABASE_URL` e `REDIS_URL` com a sintaxe `${{Postgres.DATABASE_URL}}` fazem o Railway injetar os valores dos serviços automaticamente.

> **Atenção:** Após o primeiro deploy e obter a URL pública, atualize `APP_URL` com a URL real (ex: `https://betooth-backend.up.railway.app`).

---

## 5. Rodar as migrations

Após o primeiro deploy bem-sucedido:

1. No Railway, clique no serviço do backend
2. Vá em **"Settings"** → **"Deploy"** → **Shell** (ou use o ícone de terminal)
3. Execute:
   ```bash
   npm run migrate:deploy
   ```
4. (Opcional) Para popular com dados iniciais:
   ```bash
   npm run seed
   ```

Alternativamente, adicione um **Release Command** nas configurações do serviço:
```
npm run migrate:deploy
```
Isso roda as migrations automaticamente a cada deploy.

---

## 6. Configurar Release Command (recomendado)

No Railway, vá em **Settings** do serviço → **Deploy** → **Release Command**:
```
npm run migrate:deploy
```

Isso garante que as migrations rodam antes de cada nova versão entrar em produção.

---

## 7. Verificar o deploy

Após o deploy completar, acesse:
```
GET https://<URL-RAILWAY>/api/v1/health
```

Resposta esperada:
```json
{
  "status": "ok",
  "service": "Betooth Backend"
}
```

---

## 8. Configurar Webhook do Mercado Pago

### 8.1 Acessar o painel

1. Acesse https://www.mercadopago.com.br/developers/panel/webhooks
2. Certifique-se de estar com a conta de produção selecionada (não sandbox)

### 8.2 Criar a notificação

1. Clique em **"Adicionar nova URL de notificação"** (ou "Configurar notificações")
2. Preencha:
   - **URL:** `https://<SUA-URL-RAILWAY>/api/v1/subscriptions/webhook`
     - Exemplo: `https://betooth-backend.up.railway.app/api/v1/subscriptions/webhook`
   - **Eventos a receber:**
     - [x] `payment` — pagamentos criados/atualizados (obrigatório para VIP)
     - [x] `subscription_authorized_payment` — se usar assinaturas recorrentes do MP
3. Clique em **"Salvar"**

### 8.3 Copiar o MP_WEBHOOK_SECRET

Após salvar, o painel exibe um campo **"Chave secreta"** (Webhook Secret). Copie esse valor.

### 8.4 Adicionar ao Railway

No serviço do backend no Railway → **Variables**:
```
MP_WEBHOOK_SECRET=<chave-copiada-do-painel-MP>
```

O backend já valida a assinatura automaticamente quando `MP_WEBHOOK_SECRET` está preenchido.

### 8.5 Verificar se o webhook está funcionando

Após configurar, o painel do MP tem um botão **"Testar"** / **"Enviar teste"**.
O endpoint deve responder `200 { "status": "ok", "data": { "received": true } }`.

### 8.6 Como a validação funciona (técnico)

O Mercado Pago envia o header `x-signature` no formato:
```
x-signature: ts=1698876344,v1=<hmac-sha256>
```

O backend reconstrói o template `id:<paymentId>;request-id:<x-request-id>;ts:<timestamp>;`
e valida usando HMAC-SHA256 com `MP_WEBHOOK_SECRET`.

> Se `MP_WEBHOOK_SECRET` estiver vazio, a validação é ignorada (útil em dev local).

---

## 9. Atualizar o app Flutter e a página de download

Após obter a URL pública do backend, atualize:

- **`lib/app/config/app_config.dart`**: substitua `baseUrl` pela URL do Railway
- **`web/download/index.html`**: substitua a URL de download pela URL do Railway

---

## Variáveis que precisam configuração posterior (S3)

Para upload de áudios, você precisará de um bucket S3 (AWS) ou R2 (Cloudflare):

| Variável | O que é |
|---|---|
| `S3_BUCKET` | Nome do bucket criado na AWS/Cloudflare |
| `S3_ACCESS_KEY_ID` | Access Key IAM com permissão no bucket |
| `S3_SECRET_ACCESS_KEY` | Secret da Access Key |
| `S3_REGION` | Região do bucket (ex: `sa-east-1`) |
| `S3_ENDPOINT` | Apenas para R2/MinIO (deixar vazio para AWS) |

---

## Troubleshooting

| Problema | Solução |
|---|---|
| Build falha com erro TypeScript | Verifique logs do build no Railway |
| `prisma generate` falha | O `postinstall` já roda automaticamente no `npm install` |
| Redis connection refused | Confirme que `REDIS_URL` aponta para `${{Redis.REDIS_URL}}` |
| `Invalid environment variables` | Confirme que todas as vars obrigatórias estão preenchidas |
| Health check retorna 503 | Aguarde o serviço inicializar (pode levar 30s na primeira vez) |
