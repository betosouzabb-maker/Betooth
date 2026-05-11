# Guia de Instalação do Android Studio e Build do Betooth APK (Windows 10)

> **Pré-requisito:** Windows 10 64-bit, 8 GB RAM mínimo (16 GB recomendado), 10 GB de espaço livre em disco.

---

## Sumário

1. [Instalar o Flutter SDK](#1-instalar-o-flutter-sdk)
2. [Instalar o Android Studio](#2-instalar-o-android-studio)
3. [Configurar o SDK Android e aceitar licenças](#3-configurar-o-sdk-android-e-aceitar-licenças)
4. [Configurar variáveis de ambiente (ANDROID_HOME)](#4-configurar-variáveis-de-ambiente-android_home)
5. [Verificar o ambiente com flutter doctor](#5-verificar-o-ambiente-com-flutter-doctor)
6. [Gerar o APK release do Betooth](#6-gerar-o-apk-release-do-betooth)
7. [Solução de problemas comuns](#7-solução-de-problemas-comuns)

---

## 1. Instalar o Flutter SDK

### 1.1 Baixar o Flutter

```powershell
# Crie a pasta de destino (evite espaços no caminho)
New-Item -ItemType Directory -Force -Path "C:\flutter"

# Baixe o Flutter 3.41.9 (versão exigida pelo projeto Betooth)
$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.9-stable.zip"
$dest = "$env:TEMP\flutter.zip"
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

# Extraia para C:\flutter
Expand-Archive -Path $dest -DestinationPath "C:\" -Force
Remove-Item $dest
```

> **Alternativa manual:** acesse https://flutter.dev/docs/get-started/install/windows e baixe o `.zip` da versão `3.41.9-stable`.

### 1.2 Adicionar Flutter ao PATH (sessão atual)

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
```

### 1.3 Tornar permanente via PowerShell (requer reiniciar o terminal)

```powershell
[System.Environment]::SetEnvironmentVariable(
    "PATH",
    "C:\flutter\bin;" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine"),
    "Machine"
)
```

### 1.4 Verificar instalação

```powershell
flutter --version
# Saída esperada: Flutter 3.41.9 • channel stable • ...
```

---

## 2. Instalar o Android Studio

### 2.1 Baixar o instalador

Acesse: https://developer.android.com/studio  
Clique em **Download Android Studio** e execute o instalador `.exe`.

### 2.2 Instalar (modo padrão)

Durante o assistente de instalação:

| Opção | Valor recomendado |
|---|---|
| Installation Type | **Standard** |
| UI Theme | Qualquer |
| SDK Location | `C:\Users\<seu-usuario>\AppData\Local\Android\Sdk` (padrão) |

Clique em **Finish** ao final — o Android Studio baixará os componentes do SDK automaticamente.

### 2.3 Confirmar SDK instalado via Android Studio

1. Abra o Android Studio.
2. Vá em **More Actions → SDK Manager** (ou **File → Settings → Appearance & Behavior → System Settings → Android SDK**).
3. Na aba **SDK Platforms**, marque **Android 14 (API 34)** e **Android 5.0 (API 21)**.
4. Na aba **SDK Tools**, marque:
   - Android SDK Build-Tools `34.x`
   - Android SDK Command-line Tools (latest)
   - Android Emulator
   - Android SDK Platform-Tools
5. Clique em **Apply → OK**.

---

## 3. Configurar o SDK Android e aceitar licenças

### 3.1 Aceitar todas as licenças do Android SDK

Abra um **PowerShell como Administrador** e execute:

```powershell
# Verifique o caminho do SDK (ajuste se necessário)
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"

# Aceitar licenças interativamente (responda "y" para todas)
& "$sdkPath\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
```

Se o `sdkmanager` não estiver disponível, instale as Command-line Tools:

```powershell
& "$sdkPath\cmdline-tools\latest\bin\sdkmanager.bat" "cmdline-tools;latest"
```

### 3.2 Instalar componentes mínimos via linha de comando (opcional)

```powershell
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$sdkManager = "$sdkPath\cmdline-tools\latest\bin\sdkmanager.bat"

& $sdkManager "platform-tools"
& $sdkManager "platforms;android-34"
& $sdkManager "build-tools;34.0.0"
```

---

## 4. Configurar variáveis de ambiente (ANDROID_HOME)

### 4.1 Definir ANDROID_HOME e ANDROID_SDK_ROOT

Execute no **PowerShell como Administrador**:

```powershell
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"

# ANDROID_HOME (usado pelo Flutter e ferramentas antigas)
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "Machine")

# ANDROID_SDK_ROOT (novo nome padrão)
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "Machine")

# Adicionar platform-tools e cmdline-tools ao PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$additions = "$sdkPath\platform-tools;$sdkPath\cmdline-tools\latest\bin"
[System.Environment]::SetEnvironmentVariable("PATH", "$additions;$currentPath", "Machine")

Write-Host "Variáveis configuradas. Feche e reabra o PowerShell."
```

### 4.2 Verificar as variáveis (novo terminal)

```powershell
echo $env:ANDROID_HOME
# Saída: C:\Users\<usuario>\AppData\Local\Android\Sdk

echo $env:ANDROID_SDK_ROOT
# Saída: (mesmo caminho acima)

adb version
# Saída: Android Debug Bridge version 1.x.x
```

---

## 5. Verificar o ambiente com flutter doctor

### 5.1 Executar o diagnóstico

```powershell
flutter doctor -v
```

### 5.2 Saída esperada (todos os itens verdes ou com aviso menor)

```
[✓] Flutter (Channel stable, 3.41.9, on Microsoft Windows 10)
[✓] Windows Version (10.0.xxxxx)
[!] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
    ✓ Android SDK at C:\Users\...\AppData\Local\Android\Sdk
    ✓ Platform android-34, build-tools 34.0.0
    ✓ Java binary at: ...
    ✗ Android license status unknown.
      Run `flutter doctor --android-licenses` to accept the SDK licenses.
[✓] Android Studio (version 2023.x)
[✓] VS Code (version x.x.x)
[✓] Connected device (...)
[✓] Network resources
```

### 5.3 Aceitar licenças via Flutter

```powershell
flutter doctor --android-licenses
# Responda "y" para cada licença apresentada
```

### 5.4 Re-executar após aceitar licenças

```powershell
flutter doctor
# Todos os itens relevantes devem estar [✓]
```

---

## 6. Gerar o APK release do Betooth

### 6.1 Navegar até a pasta do projeto

```powershell
Set-Location "C:\Users\cliente\Projects\betooth"
```

### 6.2 Instalar dependências Flutter

```powershell
flutter pub get
```

Saída esperada:
```
Resolving dependencies...
Got dependencies!
```

### 6.3 (Opcional) Gerar arquivos de código (Freezed / Drift)

Se o projeto usa `build_runner` (como o Betooth usa `freezed` e `drift`), rode antes do build:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 6.4 Buildar o APK release

```powershell
flutter build apk --release --build-name=1.0.0 --build-number=1
```

Progresso típico (pode demorar 5–15 min na primeira vez):
```
Running Gradle task 'assembleRelease'...
✓  Built build\app\outputs\flutter-apk\app-release.apk (xx.x MB).
```

### 6.5 Copiar o APK para a pasta de releases

```powershell
$apkSrc  = "build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "releases\android\betooth-latest.apk"

New-Item -ItemType Directory -Force -Path "releases\android" | Out-Null
Copy-Item -Path $apkSrc -Destination $apkDest -Force

$size = [math]::Round((Get-Item $apkDest).Length / 1MB, 1)
Write-Host "APK copiado: $apkDest ($size MB)" -ForegroundColor Green
```

### 6.6 Alternativa: usar o script existente

```powershell
.\deploy-download.ps1 -Platform android
```

### 6.7 Localização final do APK

```
C:\Users\cliente\Projects\betooth\
  build\app\outputs\flutter-apk\app-release.apk   ← gerado pelo Flutter
  releases\android\betooth-latest.apk              ← cópia para distribuição
```

---

## 7. Solução de problemas comuns

### Erro: `ANDROID_HOME` não definido

```powershell
# Defina para a sessão atual
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:PATH = "$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:PATH"
```

---

### Erro: `Android license status unknown`

```powershell
flutter doctor --android-licenses
# Digite "y" para cada licença
```

---

### Erro: `Gradle build failed` / `SDK Build Tools revision X not installed`

```powershell
$sdkManager = "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
& $sdkManager "build-tools;34.0.0"
```

---

### Erro: `Java not found` / `JAVA_HOME`

O Android Studio instala seu próprio JDK. Aponte o Flutter para ele:

```powershell
# Caminho típico do JDK embutido no Android Studio
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
$env:JAVA_HOME = $javaHome
$env:PATH = "$javaHome\bin;$env:PATH"

flutter config --jdk-dir "$javaHome"
```

---

### Erro: `Could not resolve com.android.tools.build:gradle`

Verifique se há acesso à internet e que o proxy corporativo não está bloqueando o Maven Central. Se usar proxy:

```powershell
# Em android\gradle.properties, adicione:
# systemProp.https.proxyHost=<seu-proxy>
# systemProp.https.proxyPort=<porta>
```

---

### Limpar cache e retentar

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

---

## Referências

- Flutter para Windows: https://docs.flutter.dev/get-started/install/windows
- Android Studio: https://developer.android.com/studio
- Flutter build APK: https://docs.flutter.dev/deployment/android
- SDK Manager CLI: https://developer.android.com/tools/sdkmanager
