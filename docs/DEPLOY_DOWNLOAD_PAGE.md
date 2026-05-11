# Guia de Deploy da Página de Download do Betooth

> **Arquivo hospedado:** `web/download/index.html`  
> A página usa QR codes dinâmicos gerados via JavaScript — ela precisa estar hospedada em HTTPS para que os QR codes apontem para a URL pública correta.

---

## Sumário

1. [Opção A – Netlify (drag-and-drop, mais rápido)](#opção-a--netlify-drag-and-drop)
2. [Opção B – Vercel (CLI)](#opção-b--vercel-cli)
3. [Configurar a URL pública na página](#configurar-a-url-pública-na-página)
4. [Testar os QR codes](#testar-os-qr-codes)
5. [Atualizar o APK após novo build](#atualizar-o-apk-após-novo-build)

---

## Opção A – Netlify (drag-and-drop)

### A.1 Criar conta gratuita

Acesse https://app.netlify.com e crie uma conta (gratuita, sem cartão).

### A.2 Deploy em 3 cliques

1. No painel do Netlify, clique em **"Add new site" → "Deploy manually"**.
2. Abra o Explorador de Arquivos e navegue até:
   ```
   C:\Users\cliente\Projects\betooth\web\download\
   ```
3. **Arraste a pasta `download`** para a área cinza do Netlify ("Drag and drop your site output folder here").
4. Aguarde alguns segundos — o Netlify exibirá uma URL pública como:
   ```
   https://random-name-123456.netlify.app
   ```

### A.3 Configurar domínio personalizado (opcional)

1. No painel do site → **"Domain settings" → "Add a domain"**.
2. Digite seu domínio (ex.: `download.betooth.app`) e siga as instruções de DNS.

### A.4 URL pública esperada

| Recurso | URL |
|---|---|
| Página de download | `https://random-name-123456.netlify.app` |
| QR Android | aponta para `https://random-name-123456.netlify.app/api/v1/app-release/android` |
| QR iOS | aponta para itms-services com `https://...` |

> **Nota:** Para que os botões de download e QR codes funcionem, você precisa de um backend servindo o APK (veja a [seção de configuração de URL](#configurar-a-url-pública-na-página)).

### A.5 Re-deploy (após atualizar o index.html)

Repita o drag-and-drop com a pasta `download` atualizada, ou conecte um repositório Git para deploy automático:

**Deploy automático via Git:**
1. **"Site configuration" → "Build & deploy" → "Link to Git provider"**
2. Selecione o repositório e configure:
   - **Base directory:** `web/download`
   - **Publish directory:** `web/download`
   - **Build command:** *(deixe vazio — é HTML estático)*
3. A cada `git push` na branch `main`, o Netlify faz re-deploy automático.

---

## Opção B – Vercel (CLI)

### B.1 Instalar o Node.js e o Vercel CLI

```powershell
# Verificar se Node.js está instalado
node --version   # Requer v18+

# Instalar globalmente o Vercel CLI
npm install -g vercel

# Verificar instalação
vercel --version
```

### B.2 Fazer login no Vercel

```powershell
vercel login
# Escolha "Continue with Email" ou GitHub/GitLab
# Siga o link enviado ao seu e-mail
```

### B.3 Deploy da pasta web/download

```powershell
# Navegue até a pasta de download
Set-Location "C:\Users\cliente\Projects\betooth\web\download"

# Primeiro deploy (interativo)
vercel

# Responda as perguntas:
#   Set up and deploy ".\download"? [Y/n]  → Y
#   Which scope? → selecione sua conta
#   Link to existing project? [y/N]        → N
#   What's your project's name?            → betooth-download
#   In which directory is your code?       → ./  (Enter)
#   Want to modify settings?               → N
```

Saída esperada:
```
✅  Preview: https://betooth-download-abc123.vercel.app [3s]
```

### B.4 Promover para produção

```powershell
vercel --prod
```

Saída esperada:
```
✅  Production: https://betooth-download.vercel.app [2s]
```

### B.5 URL pública esperada

| Recurso | URL |
|---|---|
| Produção | `https://betooth-download.vercel.app` |
| Preview (PR/branch) | `https://betooth-download-<hash>.vercel.app` |

### B.6 Re-deploy após alterações

```powershell
Set-Location "C:\Users\cliente\Projects\betooth\web\download"
vercel --prod
```

### B.7 Deploy automático via Git (Vercel + GitHub)

1. Acesse https://vercel.com/new
2. Importe o repositório GitHub do Betooth.
3. Configure:
   - **Root Directory:** `web/download`
   - **Framework Preset:** Other (sem framework)
   - **Output Directory:** `.` (ponto — pasta raiz)
4. Clique em **Deploy**.

A cada `git push` na `main`, o Vercel fará novo deploy automaticamente.

---

## Configurar a URL pública na página

A página `web/download/index.html` detecta automaticamente a URL base:

```javascript
// Linha 446 de web/download/index.html
const BASE_URL = (window.location.origin === 'null' || window.location.origin === '')
  ? 'http://localhost:3333'
  : window.location.origin;
```

### Cenário 1: Backend na mesma URL (recomendado)

Se o backend (`/api/v1/app-release/...`) estiver hospedado no mesmo domínio da página, **não é necessário nenhum ajuste** — `window.location.origin` já aponta para o lugar certo.

### Cenário 2: Backend em URL diferente

Se o APK for servido por um backend separado (ex.: `https://api.betooth.app`), edite o `index.html` para fixar a URL:

```javascript
// Substitua a lógica automática por:
const BASE_URL = 'https://api.betooth.app';
```

Ou use um arquivo `config.js` separado:

```javascript
// web/download/config.js
window.BETOOTH_API = 'https://api.betooth.app';
```

```html
<!-- No <head> do index.html, antes do </head> -->
<script src="config.js"></script>
```

```javascript
// No script principal do index.html, substitua BASE_URL por:
const BASE_URL = window.BETOOTH_API || window.location.origin;
```

### Cenário 3: Servir o APK diretamente da pasta estática

Se não houver backend, hospede o APK junto com a página e ajuste a URL:

```javascript
const ANDROID_URL = `${BASE_URL}/betooth-latest.apk`;
```

Coloque o arquivo `betooth-latest.apk` dentro de `web/download/` e suba junto com o `index.html`.

---

## Testar os QR codes

### Teste 1: Verificar geração dos QR codes

1. Abra a URL pública no navegador desktop.
2. Inspecione o console (`F12 → Console`) — não deve haver erros JavaScript.
3. Os dois QR codes (Android e iOS) devem aparecer nos cards.

### Teste 2: Verificar URL encoded no QR code

```powershell
# Instale a ferramenta de decodificação de QR (opcional)
npm install -g qrcode-terminal

# Gere o QR do Android URL para verificar
node -e "
const QRCode = require('qrcode');
const url = 'https://SEU-SITE.netlify.app/api/v1/app-release/android';
QRCode.toString(url, {type:'terminal'}, (err, str) => console.log(str));
"
```

### Teste 3: Escanear com celular Android

1. Abra a câmera do Android (ou app Google Lens).
2. Aponte para o QR Code da seção Android.
3. Toque no link exibido — deve iniciar o download do APK.

### Teste 4: Verificar HTTPS (obrigatório para iOS OTA)

```powershell
# Verificar se o site retorna 200 e usa HTTPS
Invoke-WebRequest -Uri "https://SEU-SITE.netlify.app" -UseBasicParsing | Select-Object StatusCode
# Esperado: StatusCode = 200
```

### Teste 5: Validar link de download direto

```powershell
# Substituia pela URL real do backend
$downloadUrl = "https://SEU-BACKEND/api/v1/app-release/android"
$response = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing
Write-Host "Content-Type: $($response.Headers['Content-Type'])"
# Esperado: application/vnd.android.package-archive  (ou application/octet-stream)
```

---

## Atualizar o APK após novo build

### Fluxo completo de atualização

```powershell
# 1. Gerar novo APK
Set-Location "C:\Users\cliente\Projects\betooth"
flutter build apk --release --build-name=1.0.0 --build-number=2

# 2. Copiar para releases
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
          "releases\android\betooth-latest.apk" -Force

# 3. Se o APK for servido junto com a página estática:
Copy-Item "releases\android\betooth-latest.apk" `
          "web\download\betooth-latest.apk" -Force

# 4. Re-deploy Netlify (drag-and-drop da pasta web/download)
# OU Vercel:
Set-Location "web\download"
vercel --prod
```

---

## Referências

- Netlify Deploy: https://docs.netlify.com/site-deploys/create-deploys/
- Vercel CLI: https://vercel.com/docs/cli
- Flutter Web Deploy: https://docs.flutter.dev/deployment/web
- Android APK distribution: https://developer.android.com/studio/publish#publishing-unknown
