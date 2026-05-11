# Betooth – Guia de Finalização Completo

> **Status do dia 2026-05-11**  
> Workflow CI/CD corrigido. APK será gerado no próximo push.  
> Backend ainda não hospedado. Página de download funcional mas sem URL de produção.

---

## O que foi corrigido no workflow

| Problema | Causa | Correção aplicada |
|----------|-------|-------------------|
| Flutter 3.41.9 não cacheado | Versão hotfix recente, ainda sem cache disponível no subosito/flutter-action | Alterado para `3.41.0` (versão base estável com cache disponível) |
| OOM no Gradle CI | `gradle.properties` usava `-Xmx8G` — runners do GitHub têm ~7 GB no total | Reduzido para `-Xmx4G -XX:MaxMetaspaceSize=512m` via `sed` no workflow e no arquivo local |
| Licenças Android aceitas tarde | `flutter doctor --android-licenses` ocorria após `pub get` | Movido para ANTES do `pub get` + adicionado `sdkmanager --licenses` |
| Licenças Android inconsistente | Apenas `flutter doctor` não é suficiente em alguns runners | Adicionado `sdkmanager --licenses` como chamada primária |

---

## Checklist de finalização – o que ainda falta

### 1. APK e CI/CD (obrigatório para distribuir)

- [ ] Fazer `git add . && git commit -m "fix: workflow CI corrigido" && git push`
- [ ] Acompanhar o run na aba **Actions** do GitHub
- [ ] Download o APK em: Actions → run mais recente → Artifacts → `betooth-apk-buildN`

### 2. Backend (obrigatório para o app funcionar)

O backend precisa de:
- **PostgreSQL** (banco de dados)
- **Redis** (cache, filas, sessões)
- **S3 ou equivalente** (armazenamento de áudio)
- **Servidor Node.js**

**Opção recomendada: Railway.app (gratuito até $5/mês)**

#### Passo a passo Railway

1. Acesse https://railway.app e faça login com GitHub
2. Clique em **New Project** → **Deploy from GitHub repo**
3. Selecione o repositório `betooth` e a pasta `backend` (ou configure o root como `/backend`)
4. Railway vai detectar o `package.json` automaticamente
5. Adicione os serviços:
   - Clique em **+ Add Service** → **Database** → **PostgreSQL**
   - Clique em **+ Add Service** → **Database** → **Redis**
6. Configure as variáveis de ambiente (veja seção abaixo)
7. Em **Settings** → **Networking** → **Public Domain**, gere a URL pública
   - Exemplo: `betooth-backend.up.railway.app`

#### Passo a passo Render.com (alternativa gratuita)

1. Acesse https://render.com e faça login com GitHub
2. Clique em **New** → **Web Service**
3. Selecione o repositório e configure:
   - **Root directory:** `backend`
   - **Build command:** `npm install && npm run build && npm run prisma:generate`
   - **Start command:** `npm run start`
   - **Environment:** `Node`
4. Adicione os serviços:
   - **New** → **PostgreSQL** (plano Free: 1GB)
   - **New** → **Redis** (plano Free: 25MB)
5. Copie as `DATABASE_URL` e `REDIS_URL` gerados pelo Render

### 3. Variáveis de ambiente do backend

Copie o `.env.example` e preencha com os valores reais:

```bash
# No servidor (Railway/Render), adicione estas variáveis:

NODE_ENV=production
PORT=3333
APP_URL=https://SUA_URL_BACKEND   # URL real do backend

# Banco de dados (fornecido pelo Railway/Render automaticamente)
DATABASE_URL=postgresql://user:pass@host:5432/betooth?schema=public
DIRECT_URL=postgresql://user:pass@host:5432/betooth?schema=public

# Redis (fornecido pelo Railway/Render automaticamente)
REDIS_URL=redis://user:pass@host:6379

# Secrets JWT (gere valores aleatórios fortes!)
JWT_ACCESS_SECRET=GERE_UMA_CHAVE_ALEATORIA_DE_64_CHARS
JWT_REFRESH_SECRET=GERE_OUTRA_CHAVE_ALEATORIA_DE_64_CHARS

# Mercado Pago (veja próxima seção)
MP_ACCESS_TOKEN=APP_USR-xxxx   # Token de PRODUÇÃO do Mercado Pago
MP_WEBHOOK_SECRET=SUA_CHAVE_WEBHOOK

# S3 (opcional para produção, obrigatório para upload de áudio)
S3_REGION=sa-east-1
S3_BUCKET=betooth-prod
S3_ACCESS_KEY_ID=xxxx
S3_SECRET_ACCESS_KEY=xxxx
```

**Para gerar JWT secrets no PowerShell:**
```powershell
[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
```

### 4. Rodar as migrations do banco

Depois que o backend estiver no servidor com o PostgreSQL conectado:

```bash
# No terminal do servidor (Railway: abrir shell do serviço)
cd backend
npm run migrate
npm run seed  # opcional: popula dados iniciais
```

No Railway: vá em **Settings** do serviço → **Shell** → execute os comandos acima.

### 5. Mercado Pago – Webhook

1. Acesse https://www.mercadopago.com.br/developers/panel
2. Vá em **Suas integrações** → selecione sua aplicação
3. Em **Webhooks**, clique em **Adicionar URL**:
   - **URL:** `https://SUA_URL_BACKEND/api/v1/webhooks/mercadopago`
   - **Eventos:** marque `payment` e `subscription_preapproval`
4. Copie o **secret** gerado e adicione como `MP_WEBHOOK_SECRET` nas variáveis de ambiente

> **ATENÇÃO:** O token no `.env.example` (`APP_USR-3763087...`) é um token de **teste/sandbox**.
> Para produção, gere um token de PRODUÇÃO no painel do Mercado Pago.

### 6. Página de download – URL do backend

Depois que o backend estiver hospedado, edite `web/download/index.html` linha 450:

```javascript
// Antes (desenvolvimento):
const BACKEND_ORIGIN = '';

// Depois (produção) – exemplo Railway:
const BACKEND_ORIGIN = 'https://betooth-backend.up.railway.app';
```

Depois, faça redeploy no Netlify:
1. Acesse https://app.netlify.com
2. Selecione o site do Betooth
3. Arraste novamente a pasta `web/download/` para o campo de drag-and-drop

### 7. Configurar o app Flutter com URL do backend

Verifique e atualize o arquivo de configuração do app:

```
C:\Users\cliente\Projects\betooth\lib\app\config\app_config.dart
```

A URL do backend precisa apontar para a URL de produção antes de fazer o build final do APK.

### 8. APK assinado para distribuição real

O APK atual usa a **chave de debug** (apenas para testes). Para distribuição definitiva:

1. Gere um keystore:
   ```powershell
   keytool -genkey -v -keystore betooth-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias betooth
   ```
2. Adicione em `android/app/build.gradle.kts` o bloco `signingConfigs`
3. Nunca commite o `.jks` — adicione ao `.gitignore`

---

## Checklist final consolidado

### CI/CD e APK
- [ ] `git push` com as correções do workflow
- [ ] Workflow passa (ícone verde no GitHub Actions)
- [ ] APK baixado e instalado em Android físico para teste

### Backend
- [ ] Serviço criado no Railway ou Render
- [ ] PostgreSQL adicionado e conectado
- [ ] Redis adicionado e conectado
- [ ] Variáveis de ambiente configuradas com valores de produção
- [ ] JWT secrets gerados com valores aleatórios fortes
- [ ] `npm run migrate` executado no servidor
- [ ] `GET /api/v1/health` retorna 200 na URL pública

### Mercado Pago
- [ ] Token de produção gerado (não o do `.env.example`)
- [ ] Webhook configurado no painel do Mercado Pago
- [ ] `MP_WEBHOOK_SECRET` definido nas variáveis de ambiente do servidor

### Página de download
- [ ] `BACKEND_ORIGIN` atualizada com URL de produção
- [ ] Redeploy no Netlify feito
- [ ] QR code Android testado no celular físico
- [ ] Download do APK via QR code funciona

### App Flutter
- [ ] URL do backend atualizada em `app_config.dart`
- [ ] Novo APK gerado com URL de produção via `git push`
- [ ] Login, cadastro e reprodução de música testados com backend real
- [ ] Fluxo de pagamento VIP testado (modo sandbox do Mercado Pago)

---

## Recursos úteis

| Serviço | Link | Gratuito? |
|---------|------|-----------|
| Railway | https://railway.app | Sim ($5 de crédito/mês) |
| Render | https://render.com | Sim (com cold start) |
| Netlify | https://netlify.com | Sim (100GB de banda) |
| Mercado Pago Devs | https://www.mercadopago.com.br/developers | - |
| GitHub Actions | https://github.com/actions | Sim (2000 min/mês) |
| Neon (PostgreSQL free) | https://neon.tech | Sim (0.5GB) |
| Upstash (Redis free) | https://upstash.com | Sim (10k req/dia) |
