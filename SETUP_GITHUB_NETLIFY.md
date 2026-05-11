# Guia: GitHub + CI/CD + Netlify para o Betooth

## Status atual do projeto
- Repositório Git: **já inicializado** (`C:\Users\cliente\Projects\betooth\.git`)
- Remote GitHub: **não configurado** (faça os passos abaixo)
- Workflow CI/CD: **já existe** (`.github/workflows/build-android.yml`)
- Página de download: **já existe** (`web/download/index.html`)

---

## PARTE 1 – Subir o projeto no GitHub

### 1.1 Criar o repositório no GitHub

1. Acesse **https://github.com/new**
2. Configure:
   - **Repository name:** `betooth`
   - **Visibility:** Private (recomendado) ou Public
   - **NÃO** marque "Initialize this repository with a README"
   - **NÃO** adicione .gitignore nem licença (já existe localmente)
3. Clique em **Create repository**
4. Copie a URL SSH ou HTTPS que aparecer (ex: `https://github.com/SEU_USUARIO/betooth.git`)

### 1.2 Conectar o repositório local ao GitHub

Abra o **PowerShell** na pasta do projeto e execute os comandos abaixo.
Substitua `SEU_USUARIO` pelo seu usuário do GitHub.

```powershell
# Navegue até o projeto
cd C:\Users\cliente\Projects\betooth

# Verifique os arquivos que serão commitados
git status

# Adicione todos os arquivos ao staging
git add .

# Crie o primeiro commit (se ainda não houver nenhum)
git commit -m "chore: initial commit – Flutter app + backend + download page"

# Garanta que o branch principal se chama 'main'
git branch -M main

# Conecte ao repositório remoto (substitua SEU_USUARIO)
git remote add origin https://github.com/SEU_USUARIO/betooth.git

# Envie o código
git push -u origin main
```

> **Dica:** Se o `git push` pedir autenticação, use um **Personal Access Token** (PAT):
> - Vá em GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
> - Gere um token com escopo `repo`
> - Use o token como senha quando o PowerShell pedir

### 1.3 Envios futuros (depois de cada alteração)

```powershell
cd C:\Users\cliente\Projects\betooth
git add .
git commit -m "feat: descreva o que mudou"
git push
```

---

## PARTE 2 – CI/CD no GitHub Actions (build automático do APK)

### Como o workflow funciona

O arquivo `.github/workflows/build-android.yml` já está configurado corretamente:

| Etapa | O que faz |
|-------|-----------|
| Checkout | Baixa o código do repositório |
| Java 17 | Instala o JDK necessário para o Gradle |
| Flutter 3.41.9 | Instala o Flutter SDK |
| `flutter pub get` | Instala as dependências do app |
| `build_runner` | Gera código (Freezed, Drift, json_serializable) |
| `flutter build apk --release` | Compila o APK de produção |
| Upload artifact | Salva o APK como artifact por 30 dias |

### Quando o build roda automaticamente

- A cada **push para a branch `main`**
- A cada **pull request** para `main`
- Manualmente (botão "Run workflow" na aba Actions)

### Como baixar o APK gerado

1. Acesse seu repositório no GitHub
2. Clique na aba **Actions**
3. Clique no workflow mais recente chamado **"Build Android APK"**
4. Role até a seção **Artifacts** (parte inferior da página)
5. Clique em **betooth-apk-buildNUMERO** para baixar o `.zip`
6. Descompacte o `.zip` → você terá `betooth-v1.0.0-buildNUMERO.apk`

### Verificar se o build passou

- Ícone verde ✅ = APK gerado com sucesso
- Ícone vermelho ❌ = erro (clique para ver o log completo)

---

## PARTE 3 – Deploy da página de download no Netlify

### 3.1 Primeiro deploy (drag-and-drop)

1. Acesse **https://app.netlify.com**
2. Faça login (pode usar conta GitHub)
3. Na tela inicial, clique em **"Add new site"** → **"Deploy manually"**
4. Abra o Explorer do Windows e navegue até:
   ```
   C:\Users\cliente\Projects\betooth\web\download\
   ```
5. **Arraste a pasta `download`** para a área de drop do Netlify
6. Aguarde o deploy (normalmente < 30 segundos)
7. O Netlify gerará uma URL aleatória como `https://amazing-name-123456.netlify.app`
8. Clique em **"Site configuration"** → **"Change site name"** para personalizar (ex: `betooth-download`)
   - URL final: `https://betooth-download.netlify.app`

### 3.2 Configurar a URL do backend na página

Edite o arquivo `web/download/index.html`, linha 450:

```javascript
const BACKEND_ORIGIN = 'https://SUA_URL_DO_BACKEND';
```

Exemplos:
- Render.com: `'https://betooth-api.onrender.com'`
- Railway: `'https://betooth-api.up.railway.app'`
- VPS: `'https://api.betooth.app'`

Depois faça o **redeploy** no Netlify (arraste a pasta novamente ou use o CLI).

> **Importante:** Enquanto o backend não estiver em produção, deixe `BACKEND_ORIGIN = ''`
> e os QR codes vão usar `window.location.origin` (funcionam localmente mas não no celular).

### 3.3 Testar os QR codes

**Teste completo (com backend no ar):**
1. Acesse `https://betooth-download.netlify.app` no celular
2. Abra a câmera e aponte para o QR code Android
3. O celular deve abrir o link de download do APK

**Teste básico da página (sem backend):**
```powershell
# Abrir a página localmente no navegador
Start-Process "C:\Users\cliente\Projects\betooth\web\download\index.html"
```
- Os QR codes devem renderizar (mesmo que o link não funcione sem backend)
- Se os QR codes aparecerem, a biblioteca QRCode.js está funcionando

### 3.4 Atualizar o APK quando houver novo build

Fluxo recomendado:

```
1. Faça git push para main
2. GitHub Actions roda automaticamente
3. Baixe o novo APK da aba Actions → Artifacts
4. Coloque o APK no seu servidor backend (S3, VPS, etc.)
5. A página de download já aponta para o endpoint da API — nenhuma mudança necessária na página
```

Se quiser linkar diretamente para o arquivo APK no GitHub Releases:
1. No GitHub, vá em **Releases** → **Draft a new release**
2. Faça upload do APK como asset da release
3. Copie a URL direta do asset
4. Edite `index.html` → troque `ANDROID_URL` pela URL direta

---

## Resumo dos comandos PowerShell (copy-paste)

```powershell
# Primeiro push (execute uma vez)
cd C:\Users\cliente\Projects\betooth
git add .
git commit -m "chore: initial commit"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/betooth.git
git push -u origin main

# Pushes futuros
cd C:\Users\cliente\Projects\betooth
git add .
git commit -m "mensagem descrevendo a mudança"
git push
```

---

## Checklist final

- [ ] Repositório criado em github.com/new
- [ ] `git remote add origin https://github.com/SEU_USUARIO/betooth.git`
- [ ] `git push -u origin main`
- [ ] GitHub Actions rodou com sucesso (aba Actions → ✅ verde)
- [ ] APK baixado e testado
- [ ] Pasta `web/download/` arrastada para o Netlify
- [ ] URL do Netlify personalizada
- [ ] `BACKEND_ORIGIN` configurada quando backend estiver no ar
- [ ] QR codes testados no celular
