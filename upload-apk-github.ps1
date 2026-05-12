# upload-apk-github.ps1
# Faz upload do APK para GitHub Releases usando a API do GitHub
# Uso: .\upload-apk-github.ps1 -Token "seu_github_token"
# 
# Para gerar um token: https://github.com/settings/tokens/new
# Permissoes necessarias: repo (ou apenas "Contents: write" no fine-grained token)

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    [string]$Tag = "v1.0.0",
    [string]$ApkPath = "$PSScriptRoot\releases\android\betooth-latest.apk"
)

$ErrorActionPreference = "Stop"
$REPO = "betosouzabb-maker/betooth"
$HEADERS = @{
    "Authorization" = "token $Token"
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "Betooth-Release-Script"
}

Write-Host "=== Betooth – GitHub Release Upload ===" -ForegroundColor Cyan

# Verifica APK
if (-not (Test-Path $ApkPath)) {
    Write-Host "ERRO: APK nao encontrado em: $ApkPath" -ForegroundColor Red
    Write-Host "Execute primeiro: .\build-and-release.ps1" -ForegroundColor Yellow
    exit 1
}

$apkSize = [math]::Round((Get-Item $ApkPath).Length / 1MB, 1)
Write-Host "APK: $ApkPath ($apkSize MB)" -ForegroundColor Green

# Verifica se release ja existe
Write-Host "`nVerificando release existente..." -ForegroundColor Yellow
try {
    $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/tags/$Tag" -Headers $HEADERS -Method Get
    Write-Host "Release $Tag ja existe (id: $($existing.id)). Deletando e recriando..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/$($existing.id)" -Headers $HEADERS -Method Delete | Out-Null
    # Deleta a tag tambem
    try { Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/git/refs/tags/$Tag" -Headers $HEADERS -Method Delete | Out-Null } catch {}
} catch {
    Write-Host "Nenhuma release existente. Criando nova..." -ForegroundColor Green
}

# Cria Release
Write-Host "`nCriando GitHub Release $Tag..." -ForegroundColor Green
$releaseBody = @{
    tag_name         = $Tag
    name             = "Betooth $Tag"
    body             = @"
## Betooth $Tag

APK para Android (API 21+, Android 5.0+)

**Tamanho:** ${apkSize} MB

### Como instalar:
1. Baixe o arquivo ``betooth-latest.apk`` abaixo
2. No Android: **Configuracoes > Seguranca > Fontes desconhecidas** (ative)
3. Abra o APK baixado e toque em **Instalar**
4. Abra o Betooth

> Esta versao usa chave de debug. Funcional para uso normal.
"@
    draft            = $false
    prerelease       = $false
    make_latest      = "true"
} | ConvertTo-Json

$release = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/$REPO/releases" `
    -Headers $HEADERS `
    -Method Post `
    -Body $releaseBody `
    -ContentType "application/json"

Write-Host "Release criada! ID: $($release.id)" -ForegroundColor Green

# Faz upload do APK
Write-Host "`nFazendo upload do APK..." -ForegroundColor Yellow
$uploadUrl = $release.upload_url -replace '\{\?name,label\}', ''
$apkFileName = "betooth-latest.apk"
$uploadHeaders = $HEADERS + @{ "Content-Type" = "application/vnd.android.package-archive" }

$apkBytes = [System.IO.File]::ReadAllBytes($ApkPath)
$asset = Invoke-RestMethod `
    -Uri "${uploadUrl}?name=${apkFileName}&label=Betooth+APK+(Android)" `
    -Headers $uploadHeaders `
    -Method Post `
    -Body $apkBytes

Write-Host "`n=== Upload concluido! ===" -ForegroundColor Green
Write-Host "Release URL: $($release.html_url)" -ForegroundColor Cyan
Write-Host "Download URL direto:" -ForegroundColor Yellow
Write-Host "https://github.com/$REPO/releases/download/$Tag/$apkFileName" -ForegroundColor Cyan
Write-Host "`nAtualize a pagina de download com esta URL!" -ForegroundColor Yellow
