# Betooth – Distribuição Direta (Sem Play Store / App Store)

Este documento descreve todo o sistema de distribuição direta do app **Betooth**, permitindo que usuários instalem o APK (Android) e o IPA (iOS) sem passar por lojas oficiais.

---

## Índice

1. [Visão Geral](#visão-geral)
2. [Estrutura de Arquivos](#estrutura-de-arquivos)
3. [Pré-requisitos](#pré-requisitos)
4. [Build do App](#build-do-app)
   - [Android (APK)](#android-apk)
   - [iOS (IPA)](#ios-ipa)
5. [Deploy e Distribuição](#deploy-e-distribuição)
   - [Script Linux/Mac](#script-linuxmac-build-and-deploysh)
   - [Script Windows](#script-windows-deploy-downloadps1)
6. [Backend – Endpoints de Download](#backend--endpoints-de-download)
7. [Página Web de Download](#página-web-de-download)
8. [Instalação nos Dispositivos](#instalação-nos-dispositivos)
   - [Android](#android)
   - [iOS](#ios)
9. [Variáveis de Ambiente](#variáveis-de-ambiente)
10. [Checklist de Lançamento](#checklist-de-lançamento)

---

## Visão Geral

```
betooth/
├── releases/
│   ├── android/
│   │   └── betooth-latest.apk      ← APK gerado pelo build
│   └── ios/
│       └── betooth-latest.ipa      ← IPA gerado em macOS
│
├── web/
│   └── download/
│       └── index.html              ← Página de download (dark theme + QR codes)
│
├── backend/
│   └── src/modules/app-release/
│       ├── app-release.controller.ts
│       ├── app-release.routes.ts
│       └── app-release.service.ts
│
├── build-and-deploy.sh             ← Script Linux/macOS
└── deploy-download.ps1             ← Script Windows (PowerShell)
```

---

## Pré-requisitos

| Ferramenta | Versão mínima | Link |
|---|---|---|
| Flutter | 3.22+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.4+ | (incluído no Flutter) |
| Node.js | 18+ | https://nodejs.org |
| Java JDK | 17+ | Para build Android |
| Android SDK | API 21+ | Via Android Studio |
| Xcode | 15+ | macOS apenas, para build iOS |

---

## Build do App

### Android (APK)

```bash
# 1. Instale as dependências
flutter pub get

# 2. Gere o APK release
flutter build apk --release --build-name=1.0.0 --build-number=1

# 3. O APK estará em:
#    build/app/outputs/flutter-apk/app-release.apk

# 4. Copie para a pasta de releases
cp build/app/outputs/flutter-apk/app-release.apk releases/android/betooth-latest.apk
```

> **Assinatura:** Para distribuição além da rede local, crie uma keystore e configure `android/key.properties`:
> ```
> storeFile=../keystore/betooth.keystore
> storePassword=SUA_SENHA
> keyAlias=betooth
> keyPassword=SUA_SENHA
> ```
> E em `android/app/build.gradle.kts`:
> ```kotlin
> signingConfigs {
>     create("release") {
>         val props = Properties().apply {
>             load(rootProject.file("key.properties").inputStream())
>         }
>         storeFile = file(props["storeFile"] as String)
>         storePassword = props["storePassword"] as String
>         keyAlias = props["keyAlias"] as String
>         keyPassword = props["keyPassword"] as String
>     }
> }
> ```

### iOS (IPA)

> Requer **macOS** com **Xcode 15+** e uma **Apple Developer Account** (gratuita funciona via AltStore/Sideloadly; distribuição Enterprise requer conta paga).

```bash
# 1. Instale as dependências
flutter pub get

# 2. Gere o IPA
flutter build ipa --release --build-name=1.0.0 --build-number=1

# O IPA estará em: build/ios/ipa/Runner.ipa

# 3. Copie para a pasta de releases
cp build/ios/ipa/Runner.ipa releases/ios/betooth-latest.ipa
```

**Distribuição iOS sem App Store – opções:**

| Método | Requisito | Dispositivos |
|---|---|---|
| **OTA (itms-services://)** | Certificado Enterprise | Ilimitado |
| **AltStore** | Apple ID gratuita | 3 apps / 7 dias |
| **Sideloadly** | Apple ID gratuita | 1 dispositivo por vez |
| **TestFlight** | Apple Dev Account paga | Até 10.000 testers |
| **Diawi** | Perfil AdHoc com UDIDs | Dispositivos registrados |

---

## Deploy e Distribuição

### Script Linux/macOS (`build-and-deploy.sh`)

```bash
# Tornar executável
chmod +x build-and-deploy.sh

# Build completo (Android + iOS se em Mac)
bash build-and-deploy.sh

# Apenas Android
bash build-and-deploy.sh --platform android

# Apenas iOS (requer Mac)
bash build-and-deploy.sh --platform ios

# Pular build, apenas exibir status
bash build-and-deploy.sh --skip-build
```

### Script Windows (`deploy-download.ps1`)

```powershell
# Build completo (apenas Android no Windows)
.\deploy-download.ps1

# Apenas Android
.\deploy-download.ps1 -Platform android

# Pular build + iniciar backend
.\deploy-download.ps1 -SkipBuild -BackendStart

# Build e iniciar backend
.\deploy-download.ps1 -Platform android -BackendStart
```

---

## Backend – Endpoints de Download

Os endpoints estão registrados em `backend/src/app.ts` sob o prefixo `/api/v1/app-release`.

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/api/v1/app-release/latest` | Metadados da versão (JSON) |
| `GET` | `/api/v1/app-release/android` | Download do APK |
| `GET` | `/api/v1/app-release/ios` | Download do IPA |
| `GET` | `/api/v1/app-release/ios/manifest` | Manifest OTA (`.plist`) para iOS |

### Exemplo de resposta – `/api/v1/app-release/latest`

```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "buildNumber": 1,
    "releaseDate": "2025-01-01T00:00:00Z",
    "android": {
      "available": true,
      "fileName": "betooth-latest.apk",
      "downloadUrl": "https://seu-servidor.com/api/v1/app-release/android",
      "sizeBytes": 28311552,
      "minSdkVersion": 21,
      "checksum": null
    },
    "ios": {
      "available": false,
      "fileName": "betooth-latest.ipa",
      "downloadUrl": "https://seu-servidor.com/api/v1/app-release/ios",
      "manifestUrl": "https://seu-servidor.com/api/v1/app-release/ios/manifest",
      "sizeBytes": null,
      "minOsVersion": "13.0",
      "checksum": null
    },
    "releaseNotes": "Versão inicial do Betooth."
  }
}
```

### Iniciar o backend

```bash
cd backend
cp .env.example .env   # edite as variáveis necessárias
npm install
npm run dev            # desenvolvimento
# ou
npm run build && npm start  # produção
```

O backend lê os arquivos de `releases/android/` e `releases/ios/` em relação ao `process.cwd()` (raiz do projeto).

---

## Página Web de Download

Localização: `web/download/index.html`

**Funcionalidades:**
- Tema dark premium com gradiente e animações CSS
- Botão de download Android (APK direto)
- Botão de download iOS (link OTA via `itms-services://`)
- QR Codes gerados dinamicamente (via `qrcode.js` CDN) para cada plataforma
- Instruções passo a passo para Android e iOS
- Detecta automaticamente a URL base do servidor

**Servir a página localmente:**

```bash
# Python (qualquer OS)
cd web/download && python3 -m http.server 8080

# Node.js (npx)
cd web/download && npx serve -p 8080

# PowerShell
cd web\download; python -m http.server 8080
```

**Servir via backend Express:**

Adicione no `backend/src/app.ts`:

```typescript
import path from 'path';
// Servir a pasta web/download como arquivos estáticos
app.use('/download', express.static(path.resolve(__dirname, '../../web/download')));
```

Depois acesse: `http://localhost:3333/download/`

---

## Instalação nos Dispositivos

### Android

1. **Ative "Fontes desconhecidas"** no Android:
   - Android 8+: `Configurações > Apps > Acesso especial > Instalar apps desconhecidos`
   - Android 7 e abaixo: `Configurações > Segurança > Fontes desconhecidas`

2. **Baixe o APK** pelo QR Code ou pelo botão na página de download.

3. **Instale:** toque no arquivo baixado e confirme a instalação.

4. **Abra** o Betooth normalmente.

> Caso o Android bloqueie: `Configurações > Segurança > Proteção Google Play > Desativar verificação` (temporariamente).

### iOS

#### Opção A – OTA Enterprise (recomendado para escala)

Requer um **Certificado Enterprise** (Apple Developer Enterprise Program – U$299/ano):

1. Assine o IPA com o certificado Enterprise.
2. Hospede o `betooth-latest.ipa` em um servidor HTTPS.
3. O endpoint `/api/v1/app-release/ios/manifest` já gera o `.plist` correto.
4. No iPhone, acesse a página de download e toque em "Instalar IPA (iOS)".
5. Vá em `Ajustes > Geral > VPN e Gerenciamento de Dispositivo` e confie no perfil.

#### Opção B – AltStore (gratuito, sem Enterprise)

1. Instale o [AltStore](https://altstore.io) no PC/Mac.
2. Conecte o iPhone via USB e abra o AltStore.
3. Vá em `My Apps > +` e selecione `betooth-latest.ipa`.
4. O AltStore assina e instala automaticamente (renova a cada 7 dias via Wi-Fi).

#### Opção C – Sideloadly (gratuito, sem Enterprise)

1. Baixe o [Sideloadly](https://sideloadly.io).
2. Conecte o iPhone ao PC e abra o Sideloadly.
3. Arraste o `betooth-latest.ipa` para o campo do app.
4. Insira seu Apple ID e clique em **Start**.
5. No iPhone: `Ajustes > Geral > VPN e Gerenciamento > Confiar em [seu email]`.

---

## Variáveis de Ambiente

Adicione ou confirme as seguintes variáveis em `backend/.env`:

```env
# URL pública do servidor (usado nos links de download e manifest)
APP_URL=https://seu-dominio.com

# Demais variáveis já existentes em .env.example
```

---

## Checklist de Lançamento

- [ ] `flutter pub get` executado com sucesso
- [ ] APK gerado: `releases/android/betooth-latest.apk`
- [ ] IPA gerado (se Mac): `releases/ios/betooth-latest.ipa`
- [ ] `APP_URL` configurado corretamente em `backend/.env`
- [ ] Backend rodando: `cd backend && npm run dev` (ou `npm start`)
- [ ] Página de download acessível: `http://SEU_SERVIDOR/download/`
- [ ] QR Codes renderizando na página
- [ ] Endpoint `/api/v1/app-release/latest` retornando JSON correto
- [ ] Download Android funcional (APK baixa e instala)
- [ ] Download iOS funcional (OTA, AltStore ou Sideloadly)
- [ ] Servidor com HTTPS configurado (obrigatório para iOS OTA)
- [ ] Firewall/CORS liberando os endpoints de download

---

*Betooth – Distribuição Direta v1.0.0*
