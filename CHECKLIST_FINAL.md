# Betooth – Checklist Final de Entrega

Gerado em: 2025-05-11 | **Atualizado: 2026-05-12**

---

## Status Geral

| Componente | Status | URL / Local |
|---|---|---|
| Pagina de Download | **ONLINE + ATUALIZADA** | https://betooth-download.netlify.app |
| APK Android v1.0.0 | **DISPONIVEL (64 MB)** | https://github.com/betosouzabb-maker/Betooth/releases/latest/download/betooth-latest.apk |
| GitHub Releases | **PUBLICADO** | https://github.com/betosouzabb-maker/Betooth/releases/tag/v1.0.0 |
| GitHub Actions CI | **CONFIGURADO** | Builda automaticamente a cada push para main |
| Backend (configurado) | PRONTO para deploy | Replit / Railway |
| iOS IPA | N/A | Requer Mac com Xcode |

---

## 1. APK Android – Build e Distribuicao

### Opcao A: Build Local (Recomendado – Mais Rapido)

Voce tem Flutter e Android SDK instalados. Rode no PowerShell:

```powershell
# Adiciona git ao PATH e roda o build
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
Set-Location "C:\Users\cliente\Projects\betooth"

# Build do APK release
& "C:\Users\cliente\.puro\envs\stable\flutter\bin\flutter.bat" build apk --release --build-name=1.0.0 --build-number=1

# O APK estara em:
# build\app\outputs\flutter-apk\app-release.apk
```

Depois de buildar, copie o APK para a pasta de releases:

```powershell
# Cria pasta de releases no backend
New-Item -ItemType Directory -Force -Path "C:\Users\cliente\Projects\betooth\releases\android"

# Copia o APK
Copy-Item "C:\Users\cliente\Projects\betooth\build\app\outputs\flutter-apk\app-release.apk" `
          "C:\Users\cliente\Projects\betooth\releases\android\betooth-latest.apk"

Write-Output "APK copiado com sucesso!"
```

### Opcao B: GitHub Actions (automatico a cada push)

O workflow `.github/workflows/build-android.yml` foi corrigido com:
- Flutter `stable` (sem versao fixada, usa a mais recente)
- AGP `8.3.2` (compativel com Flutter)
- Kotlin `1.9.25` (estavel)
- Gradle `8.7` (testado)
- Cria GitHub Release automaticamente apos build

Basta fazer push para `main` que o CI builda e publica o APK no GitHub Releases.

### Opcao C: GitHub Release Manual

Apos buildar o APK localmente:
1. Va em: https://github.com/betosouzabb-maker/Betooth/releases/new
2. Tag: `v1.0.0`
3. Titulo: `Betooth v1.0.0`
4. Faça upload do arquivo `app-release.apk`
5. Publique a release

---

## 2. Pagina de Download – Atualizar URL do APK

Quando o APK estiver no GitHub Releases, atualize `web/download/index.html`:

```html
<!-- Substitua a linha do BACKEND_ORIGIN por: -->
<script>
  // URL direta do APK no GitHub Releases:
  const ANDROID_APK_URL = 'https://github.com/betosouzabb-maker/Betooth/releases/latest/download/betooth.apk';
</script>
```

Ou, se quiser usar o backend para servir o APK, configure `APP_URL` no Replit apontando para a URL do seu Repl.

---

## 3. Backend – Deploy no Replit

### Passos (uma vez so):

1. Acesse https://replit.com
2. Clique em `+ Create Repl` → `Import from GitHub`
3. Cole: `https://github.com/betosouzabb-maker/Betooth`
4. Clique em `Import from GitHub`

### Adicionar servicos:
- Tools → Database → PostgreSQL → Create
- Tools → Database → Redis → Create

### Adicionar Secrets (obrigatorio):
```
JWT_ACCESS_SECRET   = (gere com: node -e "console.log(require('crypto').randomBytes(48).toString('hex'))")
JWT_REFRESH_SECRET  = (gere outro diferente)
```

### Secrets opcionais (para funcionalidades avancadas):
```
S3_BUCKET           = nome-do-seu-bucket
S3_ACCESS_KEY_ID    = sua-chave-aws
S3_SECRET_ACCESS_KEY= seu-secret-aws
S3_ENDPOINT         = (so para Cloudflare R2)
MP_ACCESS_TOKEN     = APP_USR-... (Mercado Pago)
MP_WEBHOOK_SECRET   = seu-webhook-secret
CORS_ORIGIN         = https://betooth-download.netlify.app
ADMIN_MASTER_PASSWORD = sua-senha-admin
```

### Primeiro setup (terminal do Replit):
```bash
bash setup-replit.sh
```

### Iniciar:
Clique no botao verde **Run**.

### Testar:
```
GET https://<seu-repl>.repl.co/api/v1/health
```

---

## 4. Configuracao do Mercado Pago (pos-deploy)

1. Acesse https://www.mercadopago.com.br/developers
2. Crie um app de producao
3. Copie o `MP_ACCESS_TOKEN`
4. Configure o webhook:
   - URL: `https://<seu-backend>/api/v1/subscriptions/webhook`
   - Eventos: `payment`
5. Copie o `MP_WEBHOOK_SECRET` e adicione ao Replit Secrets

---

## 5. Pagina de Download – Netlify

A pagina `web/download/index.html` esta em producao em:
https://betooth-download.netlify.app

Para re-deploy apos alteracoes:
```powershell
# No PowerShell, instale o Netlify CLI se necessario:
# npm install -g netlify-cli

# Deploy
Set-Location "C:\Users\cliente\Projects\betooth\web\download"
netlify deploy --prod --dir .
```

Ou conecte o repositorio ao Netlify para deploy automatico a cada push.

---

## 6. Arquitetura Final

```
┌─────────────────────────────────────┐
│  Usuario Android                    │
│  Acessa: betooth-download.netlify.app│
│  Baixa: betooth.apk                 │
└──────────────┬──────────────────────┘
               │ instala APK
               ▼
┌─────────────────────────────────────┐
│  App Betooth (Android)              │
│  Flutter 3.41.9 / API 21+           │
│  Conecta ao backend via API REST    │
└──────────────┬──────────────────────┘
               │ HTTPS
               ▼
┌─────────────────────────────────────┐
│  Backend (Replit / Railway)         │
│  Node.js 20 + Express + TypeScript  │
│  Prisma + PostgreSQL                │
│  Redis (cache/filas)                │
│  JWT auth + rate limiting           │
└─────────────────────────────────────┘
               │
   ┌───────────┼───────────┐
   ▼           ▼           ▼
 AWS S3    Mercado Pago  BullMQ
 (audio)   (pagamentos)  (filas)
```

---

## 7. URLs e Credenciais

| Recurso | URL |
|---|---|
| Pagina de Download | https://betooth-download.netlify.app |
| Repositorio GitHub | https://github.com/betosouzabb-maker/Betooth |
| GitHub Actions | https://github.com/betosouzabb-maker/Betooth/actions |
| GitHub Releases | https://github.com/betosouzabb-maker/Betooth/releases |
| Backend (apos deploy) | https://\<seu-repl\>.repl.co |
| Health Check | https://\<seu-repl\>.repl.co/api/v1/health |
| API de Releases | https://\<seu-repl\>.repl.co/api/v1/app-release/latest |

---

## 8. Estrutura de Arquivos Importantes

```
betooth/
├── .github/workflows/build-android.yml  # CI/CD corrigido
├── android/                              # Projeto Android (Flutter)
├── assets/                               # Assets do app (fontes, icones, etc)
│   ├── fonts/.gitkeep
│   ├── icons/.gitkeep
│   ├── images/.gitkeep
│   └── animations/.gitkeep
├── backend/                              # API REST (Node.js/Express)
│   ├── src/
│   ├── prisma/
│   ├── .env.example
│   └── package.json
├── lib/                                  # Codigo Dart/Flutter
│   ├── main.dart
│   ├── app/
│   ├── core/
│   └── features/
├── releases/                             # APK/IPA para distribuicao direta
│   ├── android/betooth-latest.apk        # <- coloque o APK aqui
│   └── ios/betooth-latest.ipa            # <- coloque o IPA aqui (Mac)
├── web/download/index.html               # Pagina de download (Netlify)
├── setup-replit.sh                       # Setup automatico do Replit
├── .replit                               # Config do Replit
├── replit.nix                            # Deps do Replit
├── DEPLOY-REPLIT.md                      # Guia de deploy no Replit
└── CHECKLIST_FINAL.md                    # Este arquivo
```

---

## 9. Proximos Passos Prioritarios

- [ ] **APK**: Buildar e fazer upload para GitHub Releases
- [ ] **Pagina de Download**: Atualizar URL do APK com link direto do GitHub Releases
- [ ] **Backend**: Fazer deploy no Replit (5 minutos)
- [ ] **JWT Secrets**: Gerar e configurar no Replit Secrets
- [ ] **Mercado Pago**: Configurar token e webhook apos deploy
- [ ] **S3/R2**: Configurar bucket para uploads de audio
- [ ] **CORS**: Configurar `CORS_ORIGIN` com URL do frontend no backend

---

## 10. Comandos Uteis (PowerShell)

### Build APK local:
```powershell
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
& "C:\Users\cliente\.puro\envs\stable\flutter\bin\flutter.bat" build apk --release
```

### Verificar saude do app Flutter:
```powershell
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
& "C:\Users\cliente\.puro\envs\stable\flutter\bin\flutter.bat" doctor
```

### Gerar JWT secrets:
```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

### Deploy Netlify:
```powershell
Set-Location "C:\Users\cliente\Projects\betooth\web\download"
netlify deploy --prod --dir .
```
