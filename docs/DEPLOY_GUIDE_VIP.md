# Betooth - Guia de Deploy Completo (Atualizado com VIP)

## Pré-requisitos

### Ambiente de Desenvolvimento
- Node.js 18+ (recomendado: 20 LTS)
- Flutter 3.41.9+ (instalado via Puro ou oficial)
- Dart 3.11.5+
- PostgreSQL 15+
- Redis 7+
- Conta AWS (ou S3-compatible)
- **Conta Mercado Pago** (para pagamentos VIP)

---

## 1. Configurar Mercado Pago (NOVO - Sistema VIP)

### 1.1 Criar Conta e Aplicação
1. Acesse [Mercado Pago Developers](https://www.mercadopago.com.br/developers)
2. Crie uma conta ou faça login
3. Vá em "Suas Aplicações" → "Criar nova aplicação"
4. Nome: `Betooth`
5. Tipo: `Marketplace / Plataforma`
6. Copie o **Access Token** de produção

### 1.2 Configurar Webhook
1. No painel do Mercado Pago, vá em "Webhooks"
2. URL: `https://api.betooth.com/api/v1/subscriptions/webhook`
3. Eventos: `payment`, `subscription_authorized`, `subscription_cancelled`
4. Copie o **Secret do Webhook** para validação HMAC

### 1.3 Criar Plano de Assinatura
1. Vá em "Assinaturas" → "Criar plano"
2. Nome: `Betooth VIP Mensal`
3. Preço: R$9,99
4. Frequência: Mensal
5. Copie o **ID do Plano** (será o `externalSubId`)

---

## 2. Backend Deploy

### 2.1 Configurar Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env`:

```bash
cd backend
cp .env.example .env
```

Edite `.env`:

```env
# App
NODE_ENV=production
PORT=3000
API_PREFIX=/api/v1

# JWT
JWT_SECRET=seu-secret-super-seguro-minimo-32-caracteres
JWT_REFRESH_SECRET=seu-refresh-secret-diferente
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# Database
DATABASE_URL=postgresql://user:password@host:5432/betooth?schema=public

# Redis
REDIS_URL=redis://localhost:6379

# Storage (AWS S3 ou compatível)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=seu-access-key
AWS_SECRET_ACCESS_KEY=seu-secret-key
S3_BUCKET=betooth-media
S3_ENDPOINT=https://s3.us-east-1.amazonaws.com

# Admin
ADMIN_MASTER_PASSWORD=sua-senha-mestre-super-segura

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# === MERCADO PAGO (NOVO - Sistema VIP) ===
MP_ACCESS_TOKEN=SEU_ACCESS_TOKEN_DO_MERCADO_PAGO
MP_WEBHOOK_SECRET=SEU_SECRET_DO_WEBHOOK
MP_PLAN_PRICE_CENTS=999
MP_PLAN_LABEL=Betooth VIP Mensal

# Download Quota (NOVO)
FREE_MONTHLY_DOWNLOAD_LIMIT=5

# VIP Cache
VIP_CACHE_TTL_SECONDS=300
```

### 2.2 Instalar Dependências

```bash
cd backend
npm install
```

### 2.3 Configurar Banco de Dados

```bash
# Gerar cliente Prisma
npx prisma generate

# Executar migrations (inclui novas tabelas VIP)
npx prisma migrate deploy

# (Opcional) Seed inicial
npx prisma db seed
```

### 2.4 Compilar TypeScript

```bash
npm run build
```

### 2.5 Iniciar Servidor

```bash
# Produção
npm start

# Ou com PM2
npm install -g pm2
pm2 start dist/server.js --name betooth-api
pm2 save
pm2 startup
```

### 2.6 Verificar Health Check

```bash
curl http://localhost:3000/api/v1/health
# Esperado: {"status":"ok"}
```

### 2.7 Testar VIP (NOVO)

```bash
# Verificar quota de downloads (usuário free)
curl -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/downloads/quota
# Esperado: {"used":0,"limit":5,"isVip":false}

# Tentar upload sem VIP (deve falhar)
curl -X POST -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/uploads/init
# Esperado: 403 VIP_REQUIRED
```

---

## 3. Deploy em Produção (Docker - Recomendado)

### 3.1 Docker Compose

Crie `docker-compose.yml` na raiz:

```yaml
version: '3.8'

services:
  api:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/betooth
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - S3_BUCKET=${S3_BUCKET}
      - ADMIN_MASTER_PASSWORD=${ADMIN_MASTER_PASSWORD}
      - MP_ACCESS_TOKEN=${MP_ACCESS_TOKEN}
      - MP_WEBHOOK_SECRET=${MP_WEBHOOK_SECRET}
      - MP_PLAN_PRICE_CENTS=999
      - FREE_MONTHLY_DOWNLOAD_LIMIT=5
      - VIP_CACHE_TTL_SECONDS=300
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: betooth
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    restart: unless-stopped

volumes:
  postgres_data:
```

### 3.2 Dockerfile (backend/)

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY prisma ./prisma/
RUN npx prisma generate
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### 3.3 Executar

```bash
docker-compose up -d
```

---

## 4. Flutter Build

### 4.1 Configurar API Base URL

Edite `lib/app/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://api.betooth.com/api/v1';
  static const String appName = 'Betooth';
}
```

### 4.2 Configurar Deep Link (NOVO - VIP)

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="betooth" android:host="vip-success" />
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>betooth</string>
        </array>
    </dict>
</array>
```

### 4.3 Build Android

```bash
# APK de release
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle --release
```

Saída:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 4.4 Build iOS

```bash
# Requer macOS + Xcode
flutter build ios --release

# Para App Store
flutter build ipa --release
```

### 4.5 Configurar Assinatura (Android)

Crie `android/key.properties`:

```properties
storePassword=sua-senha
keyPassword=sua-senha
keyAlias=betooth
storeFile=betooth.keystore
```

Gere keystore:

```bash
keytool -genkey -v -keystore betooth.keystore -alias betooth -keyalg RSA -keysize 2048 -validity 10000
```

---

## 5. Publicação

### 5.1 Play Store (Android)

1. Crie conta de desenvolvedor Google ($25)
2. Acesse [Google Play Console](https://play.google.com/console)
3. Crie novo app
4. Faça upload do AAB (`flutter build appbundle`)
5. Preencha informações do app
6. Configure classificação de conteúdo
7. Envie para revisão

### 5.2 App Store (iOS)

1. Crie conta Apple Developer ($99/ano)
2. Acesse [App Store Connect](https://appstoreconnect.apple.com)
3. Crie novo app
4. Configure certificados e provisioning profiles
5. Archive e upload via Xcode Organizer
6. Envie para revisão

---

## 6. Configuração Firebase (Opcional)

Para push notifications reais via FCM:

1. Crie projeto no [Firebase Console](https://console.firebase.google.com)
2. Adicione apps Android e iOS
3. Baixe `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
4. Coloque em:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
5. Configure `firebase_messaging` no Flutter

---

## 7. Monitoramento

### Logs
- Backend usa Pino (estruturado)
- Configure coleta de logs (Datadog, Logtail, CloudWatch)

### Métricas VIP (NOVO)
- Taxa de conversão free → VIP
- Churn rate (cancelamentos)
- Receita mensal recorrente (MRR)
- Uso de cupons
- Downloads por tier (free vs VIP)

### Alertas
- Erro rate > 1%
- Latência p95 > 500ms
- Fila de uploads acumulada
- Webhook MP falhando
- Assinaturas expirando em massa

---

## 8. Backup

### Banco de Dados
```bash
# Backup diário automatizado
pg_dump -h localhost -U postgres betooth > backup_$(date +%Y%m%d).sql

# Restore
psql -h localhost -U postgres betooth < backup_20260101.sql
```

### Storage (S3)
- Habilite versioning no bucket
- Configure lifecycle policies
- Cross-region replication

---

## 9. Escalabilidade

### Horizontal Scaling
- Load balancer (AWS ALB, Nginx)
- Múltiplas instâncias do container Node.js
- Workers separados para processamento de uploads

### Database
- Read replicas para queries de leitura
- Connection pooling (PgBouncer)
- Particionamento de tabelas grandes

### Cache
- Redis cluster
- Cache de VIP status (TTL 5min)

---

## 10. Checklist Pré-Deploy

- [ ] Variáveis de ambiente configuradas (incluindo MP_ACCESS_TOKEN)
- [ ] Banco de dados migrado (tabelas VIP incluídas)
- [ ] Redis conectado
- [ ] S3/storage configurado
- [ ] Mercado Pago webhook configurado
- [ ] SSL/TLS ativo
- [ ] Rate limiting habilitado
- [ ] Logs configurados
- [ ] Backups automatizados
- [ ] APK/AAB assinado
- [ ] Deep links configurados (betooth://vip-success)
- [ ] Screenshots e descrição prontos
- [ ] Política de privacidade publicada
- [ ] Termos de uso publicados

---

*Guia atualizado em 11/05/2026 com Sistema VIP*
