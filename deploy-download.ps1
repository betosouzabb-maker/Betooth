#Requires -Version 5.1
<#
.SYNOPSIS
    deploy-download.ps1 – Betooth · Distribuição Direta (Windows / PowerShell)

.DESCRIPTION
    Orquestra o build Flutter (APK/IPA), copia artefatos para releases/ e
    imprime o status final. IPA só é gerado em macOS; no Windows gera apenas APK.

.PARAMETER Platform
    android | ios | all  (padrão: all)

.PARAMETER SkipBuild
    Pula o flutter build e apenas reporta o status atual dos arquivos.

.PARAMETER BackendStart
    Após o deploy, inicia o backend (cd backend; npm run dev).

.EXAMPLE
    .\deploy-download.ps1
    .\deploy-download.ps1 -Platform android
    .\deploy-download.ps1 -SkipBuild
    .\deploy-download.ps1 -Platform android -BackendStart
#>

[CmdletBinding()]
param(
    [ValidateSet('android','ios','all')]
    [string]$Platform = 'all',

    [switch]$SkipBuild,

    [switch]$BackendStart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------- helpers ----------------------------------------------------------
function Write-Info    { param($m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok      { param($m) Write-Host "[ OK ] $m" -ForegroundColor Green }
function Write-Warn    { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err     { param($m) Write-Error "[ERR]  $m" }

# ---------- caminhos ---------------------------------------------------------
$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ReleasesDir     = Join-Path $ScriptDir "releases"
$ReleasesAndroid = Join-Path $ReleasesDir "android"
$ReleasesIos     = Join-Path $ReleasesDir "ios"
$WebDownload     = Join-Path $ScriptDir "web\download"

New-Item -ItemType Directory -Force -Path $ReleasesAndroid | Out-Null
New-Item -ItemType Directory -Force -Path $ReleasesIos     | Out-Null

# ---------- verificar Flutter ------------------------------------------------
function Assert-Flutter {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) {
        Write-Warn "Flutter não encontrado no PATH."
        Write-Warn "Instale em: https://docs.flutter.dev/get-started/install"
        Write-Warn "Adicione ao PATH: C:\flutter\bin"
        throw "Flutter não encontrado."
    }
    Write-Info "Flutter: $((flutter --version 2>&1)[0])"
}

# ---------- build Android ----------------------------------------------------
function Build-Android {
    Write-Info "Iniciando build Android (APK release)…"
    Set-Location $ScriptDir

    flutter pub get
    flutter build apk --release --build-name=1.0.0 --build-number=1

    $apkSrc = Join-Path $ScriptDir "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkSrc)) {
        Write-Err "APK não encontrado em: $apkSrc"
    }

    $dest = Join-Path $ReleasesAndroid "betooth-latest.apk"
    Copy-Item -Path $apkSrc -Destination $dest -Force
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Ok "APK copiado → releases\android\betooth-latest.apk (${size} MB)"
}

# ---------- build iOS --------------------------------------------------------
function Build-Ios {
    Write-Warn "Build iOS requer macOS + Xcode. No Windows, este passo é ignorado."
    Write-Warn "Para gerar o IPA:"
    Write-Warn "  1. Clone o projeto em um Mac com Xcode 15+"
    Write-Warn "  2. Execute: bash build-and-deploy.sh --platform ios"
    Write-Warn "  3. Copie releases/ios/betooth-latest.ipa para este servidor"
}

# ---------- status -----------------------------------------------------------
function Show-Status {
    $sep = "=" * 50
    Write-Host ""
    Write-Host $sep -ForegroundColor Magenta
    Write-Host "  Betooth – Status de Distribuição Direta" -ForegroundColor White
    Write-Host $sep -ForegroundColor Magenta

    $apk = Join-Path $ReleasesAndroid "betooth-latest.apk"
    $ipa = Join-Path $ReleasesIos "betooth-latest.ipa"
    $page = Join-Path $WebDownload "index.html"

    if (Test-Path $apk) {
        $sz = [math]::Round((Get-Item $apk).Length / 1MB, 1)
        Write-Host "  [+] Android APK  -> releases\android\betooth-latest.apk ($sz MB)" -ForegroundColor Green
    } else {
        Write-Host "  [-] Android APK  -> nao encontrado" -ForegroundColor Red
    }

    if (Test-Path $ipa) {
        $sz = [math]::Round((Get-Item $ipa).Length / 1MB, 1)
        Write-Host "  [+] iOS IPA      -> releases\ios\betooth-latest.ipa ($sz MB)" -ForegroundColor Green
    } else {
        Write-Host "  [-] iOS IPA      -> requer macOS + Xcode" -ForegroundColor Yellow
    }

    if (Test-Path $page) {
        Write-Host "  [+] Download page -> web\download\index.html" -ForegroundColor Green
    } else {
        Write-Host "  [-] Download page -> nao encontrada" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Backend endpoints:" -ForegroundColor Cyan
    Write-Host "    GET /api/v1/app-release/latest"
    Write-Host "    GET /api/v1/app-release/android  (download APK)"
    Write-Host "    GET /api/v1/app-release/ios       (download IPA)"
    Write-Host "    GET /api/v1/app-release/ios/manifest"
    Write-Host ""
    Write-Host "  Iniciar backend:" -ForegroundColor Cyan
    Write-Host "    cd backend; npm run dev"
    Write-Host ""
    Write-Host "  Abrir pagina de download:" -ForegroundColor Cyan
    Write-Host "    Start-Process 'http://localhost:3333/download/'"
    Write-Host $sep -ForegroundColor Magenta
}

# ---------- execução ---------------------------------------------------------
if (-not $SkipBuild) {
    Assert-Flutter
}

switch ($Platform) {
    'android' {
        if (-not $SkipBuild) { Build-Android }
    }
    'ios' {
        if (-not $SkipBuild) { Build-Ios }
    }
    'all' {
        if (-not $SkipBuild) {
            Build-Android
            Build-Ios
        }
    }
}

Show-Status

if ($BackendStart) {
    Write-Info "Iniciando backend (npm run dev)…"
    Set-Location (Join-Path $ScriptDir "backend")
    npm run dev
}
