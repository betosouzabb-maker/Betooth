# build-and-release.ps1
# Script para buildar o APK e fazer upload para GitHub Releases
# Uso: .\build-and-release.ps1
# Prerequisito: gh CLI instalado (https://cli.github.com)

param(
    [string]$Version = "1.0.0",
    [string]$BuildNumber = "1"
)

$ErrorActionPreference = "Stop"
$FLUTTER = "C:\Users\cliente\.puro\envs\stable\flutter\bin\flutter.bat"
$GIT = "C:\Program Files\Git\bin\git.exe"
$PROJECT_ROOT = $PSScriptRoot

Write-Host "=== Betooth Build & Release Script ===" -ForegroundColor Cyan
Write-Host "Versao: $Version (build $BuildNumber)" -ForegroundColor Yellow

# ── 1. Adiciona Git ao PATH ──────────────────────────────────────────────────
$env:PATH = "C:\Program Files\Git\bin;" + $env:PATH
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

if (-not (Test-Path $FLUTTER)) {
    Write-Host "ERRO: Flutter nao encontrado em $FLUTTER" -ForegroundColor Red
    exit 1
}

# ── 2. Entra no diretorio do projeto ─────────────────────────────────────────
Set-Location $PROJECT_ROOT
Write-Host "`n[1/5] Diretorio: $PROJECT_ROOT" -ForegroundColor Green

# ── 3. flutter pub get ────────────────────────────────────────────────────────
Write-Host "`n[2/5] Instalando dependencias Flutter..." -ForegroundColor Green
& $FLUTTER pub get
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO: flutter pub get falhou" -ForegroundColor Red; exit 1 }

# ── 4. Build APK ─────────────────────────────────────────────────────────────
Write-Host "`n[3/5] Buildando APK release (pode demorar 5-10 min na primeira vez)..." -ForegroundColor Green
& $FLUTTER build apk --release --build-name=$Version --build-number=$BuildNumber
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO: flutter build apk falhou" -ForegroundColor Red; exit 1 }

$APK_SRC = "$PROJECT_ROOT\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $APK_SRC)) {
    Write-Host "ERRO: APK nao encontrado em $APK_SRC" -ForegroundColor Red
    exit 1
}

# ── 5. Copia APK para releases/ ───────────────────────────────────────────────
Write-Host "`n[4/5] Copiando APK..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "$PROJECT_ROOT\releases\android" | Out-Null
Copy-Item $APK_SRC "$PROJECT_ROOT\releases\android\betooth-latest.apk" -Force
$APK_DEST = "$PROJECT_ROOT\releases\android\betooth-latest.apk"
$APK_SIZE = [math]::Round((Get-Item $APK_DEST).Length / 1MB, 1)
Write-Host "APK copiado: $APK_DEST ($APK_SIZE MB)" -ForegroundColor Cyan

# ── 6. GitHub Release (opcional, requer gh CLI) ───────────────────────────────
Write-Host "`n[5/5] Verificando gh CLI..." -ForegroundColor Green
$ghAvailable = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)

if ($ghAvailable) {
    $TAG = "v${Version}-build${BuildNumber}"
    Write-Host "Criando GitHub Release $TAG..." -ForegroundColor Green
    
    # Verifica se ja esta autenticado
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "AVISO: Nao autenticado no gh. Rode 'gh auth login' primeiro." -ForegroundColor Yellow
        Write-Host "APK disponivel em: $APK_DEST" -ForegroundColor Cyan
    } else {
        Set-Location $PROJECT_ROOT
        gh release create $TAG $APK_DEST `
            --title "Betooth v$Version (build $BuildNumber)" `
            --notes "## Betooth v$Version`n`nAPK para Android (API 21+, Android 5.0+)`n`nTamanho: ${APK_SIZE} MB`n`n### Como instalar:`n1. Baixe o arquivo abaixo`n2. No Android: Configuracoes > Seguranca > Fontes desconhecidas > Ativar`n3. Abra o APK e toque em Instalar" `
            --latest
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nRelease criada com sucesso!" -ForegroundColor Green
            Write-Host "URL: https://github.com/betosouzabb-maker/Betooth/releases/tag/$TAG" -ForegroundColor Cyan
            Write-Host "`nURL direta do APK:" -ForegroundColor Yellow
            Write-Host "https://github.com/betosouzabb-maker/Betooth/releases/download/$TAG/betooth-latest.apk" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "AVISO: gh CLI nao instalado. Para publicar automaticamente:" -ForegroundColor Yellow
    Write-Host "1. Instale: https://cli.github.com" -ForegroundColor White
    Write-Host "2. Rode: gh auth login" -ForegroundColor White
    Write-Host "3. Rode este script novamente" -ForegroundColor White
    Write-Host "`nOu suba manualmente em:" -ForegroundColor Yellow
    Write-Host "https://github.com/betosouzabb-maker/Betooth/releases/new" -ForegroundColor Cyan
    Write-Host "APK: $APK_DEST ($APK_SIZE MB)" -ForegroundColor Cyan
}

Write-Host "`n=== Build concluido com sucesso! ===" -ForegroundColor Green
