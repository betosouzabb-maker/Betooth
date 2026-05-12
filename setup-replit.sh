#!/usr/bin/env bash
# =============================================================
# Betooth — Replit Setup Script
# Roda migrations do Prisma e seed inicial
# =============================================================

set -e

echo "==> Betooth: iniciando setup no Replit..."

cd "$(dirname "$0")/backend"

echo "==> Instalando dependências..."
npm ci

echo "==> Gerando Prisma Client..."
npx prisma generate

echo "==> Rodando migrations..."
npx prisma migrate deploy

echo "==> Rodando seed (se existir)..."
npx prisma db seed || echo "Seed não encontrado ou já executado, pulando..."

echo ""
echo "✓ Setup concluído! Backend pronto para uso."
echo "  URL: http://0.0.0.0:${PORT:-3333}"
