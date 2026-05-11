#!/usr/bin/env bash
# =============================================================================
# build-and-deploy.sh  –  Betooth · Distribuição Direta
# Uso: bash build-and-deploy.sh [--platform android|ios|all] [--skip-build]
# =============================================================================
set -euo pipefail

# ---------- cores ------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---------- parâmetros -------------------------------------------------------
PLATFORM="all"
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --platform) PLATFORM="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    *) error "Parâmetro desconhecido: $1. Use --platform android|ios|all ou --skip-build" ;;
  esac
done

# ---------- caminhos ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASES_DIR="$SCRIPT_DIR/releases"
RELEASES_ANDROID="$RELEASES_DIR/android"
RELEASES_IOS="$RELEASES_DIR/ios"
WEB_DOWNLOAD="$SCRIPT_DIR/web/download"

mkdir -p "$RELEASES_ANDROID" "$RELEASES_IOS"

# ---------- verificar Flutter ------------------------------------------------
check_flutter() {
  if ! command -v flutter &>/dev/null; then
    error "Flutter não encontrado no PATH.
Instale em: https://docs.flutter.dev/get-started/install
Ou configure FLUTTER_ROOT e adicione ao PATH:
  export PATH=\"\$FLUTTER_ROOT/bin:\$PATH\""
  fi
  info "Flutter: $(flutter --version 2>&1 | head -1)"
}

# ---------- build Android ----------------------------------------------------
build_android() {
  info "Iniciando build Android (APK release)…"
  cd "$SCRIPT_DIR"

  flutter pub get

  flutter build apk --release \
    --build-name=1.0.0 \
    --build-number=1

  APK_SRC="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"

  if [[ ! -f "$APK_SRC" ]]; then
    error "APK não encontrado em: $APK_SRC"
  fi

  cp "$APK_SRC" "$RELEASES_ANDROID/betooth-latest.apk"
  success "APK copiado para releases/android/betooth-latest.apk ($(du -sh "$RELEASES_ANDROID/betooth-latest.apk" | cut -f1))"
}

# ---------- build iOS --------------------------------------------------------
build_ios() {
  if [[ "$(uname)" != "Darwin" ]]; then
    warn "Build iOS requer macOS + Xcode. Pulando…"
    warn "Para buildar iOS:"
    warn "  1. Clone o projeto em um Mac com Xcode 15+"
    warn "  2. Execute: bash build-and-deploy.sh --platform ios"
    warn "  3. Copie releases/ios/betooth-latest.ipa para este servidor"
    return 0
  fi

  info "Iniciando build iOS (IPA release)…"
  cd "$SCRIPT_DIR"

  flutter pub get

  # Build IPA sem assinatura automática (necessário provisioning profile)
  flutter build ipa --release \
    --build-name=1.0.0 \
    --build-number=1 \
    --no-codesign || {
      warn "Build sem codesign concluído. Para distribuição Enterprise/AdHoc"
      warn "você precisará assinar o IPA com um certificado válido."
    }

  IPA_SRC="$SCRIPT_DIR/build/ios/ipa/Runner.ipa"

  if [[ -f "$IPA_SRC" ]]; then
    cp "$IPA_SRC" "$RELEASES_IOS/betooth-latest.ipa"
    success "IPA copiado para releases/ios/betooth-latest.ipa"
  else
    warn "IPA não encontrado em $IPA_SRC. Verifique o build."
  fi
}

# ---------- deploy da página de download -------------------------------------
deploy_web() {
  info "Verificando página de download em web/download/index.html…"

  if [[ ! -f "$WEB_DOWNLOAD/index.html" ]]; then
    error "web/download/index.html não encontrado."
  fi

  success "Página de download pronta em: $WEB_DOWNLOAD/index.html"
  info "Para servir localmente:"
  info "  cd web/download && python3 -m http.server 8080"
  info "  Acesse: http://localhost:8080"
}

# ---------- status final -----------------------------------------------------
print_status() {
  echo ""
  echo -e "${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${BOLD}   Betooth – Status de Distribuição Direta${NC}"
  echo -e "${BOLD}════════════════════════════════════════════${NC}"

  if [[ -f "$RELEASES_ANDROID/betooth-latest.apk" ]]; then
    SIZE=$(du -sh "$RELEASES_ANDROID/betooth-latest.apk" | cut -f1)
    echo -e "  ${GREEN}✓${NC} Android APK  → releases/android/betooth-latest.apk (${SIZE})"
  else
    echo -e "  ${RED}✗${NC} Android APK  → não encontrado"
  fi

  if [[ -f "$RELEASES_IOS/betooth-latest.ipa" ]]; then
    SIZE=$(du -sh "$RELEASES_IOS/betooth-latest.ipa" | cut -f1)
    echo -e "  ${GREEN}✓${NC} iOS IPA      → releases/ios/betooth-latest.ipa (${SIZE})"
  else
    echo -e "  ${YELLOW}–${NC} iOS IPA      → requer macOS + Xcode"
  fi

  echo -e "  ${GREEN}✓${NC} Download page → web/download/index.html"
  echo ""
  echo -e "  ${CYAN}Backend endpoints:${NC}"
  echo -e "    GET /api/v1/app-release/latest"
  echo -e "    GET /api/v1/app-release/android  (download APK)"
  echo -e "    GET /api/v1/app-release/ios       (download IPA)"
  echo -e "    GET /api/v1/app-release/ios/manifest"
  echo ""
  echo -e "  ${CYAN}Para iniciar o backend:${NC}"
  echo -e "    cd backend && npm run dev"
  echo ""
  echo -e "  ${CYAN}Para servir a página de download:${NC}"
  echo -e "    cd web/download && python3 -m http.server 8080"
  echo -e "${BOLD}════════════════════════════════════════════${NC}"
}

# ---------- execução ---------------------------------------------------------
if [[ "$SKIP_BUILD" == "false" ]]; then
  check_flutter
fi

case "$PLATFORM" in
  android)
    [[ "$SKIP_BUILD" == "false" ]] && build_android || true
    ;;
  ios)
    [[ "$SKIP_BUILD" == "false" ]] && build_ios || true
    ;;
  all)
    if [[ "$SKIP_BUILD" == "false" ]]; then
      build_android
      build_ios
    fi
    ;;
  *)
    error "Platform inválido: $PLATFORM. Use android, ios ou all."
    ;;
esac

deploy_web
print_status
