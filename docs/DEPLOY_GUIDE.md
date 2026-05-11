# Betooth - Guia de Deploy

## Pré-requisitos

### Ambiente de Desenvolvimento
- Node.js 18+ (recomendado: 20 LTS)
- Flutter 3.41.9+ (instalado via Puro ou oficial)
- Dart 3.11.5+
- PostgreSQL 15+
- Redis 7+
- Conta AWS (ou S3-compatible: MinIO, Cloudflare R2, DigitalOcean Spaces)

---

## 1. Backend Deploy

### 1.1 Configurar Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env` e preencha:

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
```

### 1.2 Instalar Dependências

```bash
cd backend
npm install
```

### 1.3 Configurar Banco de Dados

```bash
# Gerar cliente Prisma
npx prisma generate

# Executar migrations
npx prisma migrate deploy

# (Opcional) Seed inicial
npx prisma db seed
```

### 1.4 Compilar TypeScript

```bash
npm run build
```

### 1.5 Iniciar Servidor

```bash
# Produção
npm start

# Ou com PM2
npm install -g pm2
pm2 start dist/server.js --name betooth-api
pm2 save
pm2 startup
```

### 1.6 Verificar Health Check

```bash
curl http://localhost:3000/api/v1/health
# Esperado: {"status":"ok"}
```

---

## 2. Deploy em Produção (Recomendado)

### Opção A: Docker (Recomendado)

Crie um `docker-compose.yml` na raiz do projeto:

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

Crie um `Dockerfile` no `backend/`:

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

Execute:

```bash
docker-compose up -d
```

### Opção B: VPS/Cloud (AWS EC2, DigitalOcean, etc.)

1. Provisione servidor com Ubuntu 22.04
2. Instale Node.js, PostgreSQL, Redis
3. Clone o repositório
4. Siga os passos 1.1 a 1.5
5. Configure Nginx como reverse proxy:

```nginx
server {
    listen 80;
    server_name api.betooth.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

6. Configure SSL com Let's Encrypt:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.betooth.com
```

---

## 3. Flutter Build

### 3.1 Configurar API Base URL

Edite `lib/app/config/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://api.betooth.com/api/v1';
  static const String appName = 'Betooth';
}
```

### 3.2 Build Android

```bash
# APK de release
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle --release
```

Saída:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 3.3 Build iOS

```bash
# Requer macOS + Xcode
flutter build ios --release

# Para App Store
flutter build ipa --release
```

Saída:
- `.xcarchive` em `build/ios/archive/`
- `.ipa` em `build/ios/ipa/`

### 3.4 Configurar Assinatura (Android)

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

Configure `android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            keyAlias = "betooth"
            keyPassword = "sua-senha"
            storeFile = file("betooth.keystore")
            storePassword = "sua-senha"
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 4. Publicação

### Play Store (Android)

1. Crie conta de desenvolvedor Google ($25)
2. Acesse [Google Play Console](https://play.google.com/console)
3. Crie novo app
4. Faça upload do AAB (`flutter build appbundle`)
5. Preencha informações do app (título, descrição, screenshots)
6. Configure classificação de conteúdo
7. Defina preço/países
8. Envie para revisão

### App Store (iOS)

1. Crie conta Apple Developer ($99/ano)
2. Acesse [App Store Connect](https://appstoreconnect.apple.com)
3. Crie novo app
4. Configure certificados e provisioning profiles no Xcode
5. Archive e upload via Xcode Organizer
6. Preencha informações do app
7. Envie para revisão

---

## 5. Configuração Firebase (Opcional)

Para push notifications reais via FCM:

1. Crie projeto no [Firebase Console](https://console.firebase.google.com)
2. Adicione apps Android e iOS
3. Baixe `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
4. Coloque em:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
5. Configure `firebase_messaging` no Flutter
6. Configure backend para enviar push via FCM Admin SDK

---

## 6. Monitoramento

### Logs
- Backend usa Pino (estruturado)
- Configure coleta de logs (Datadog, Logtail, ou CloudWatch)

### Métricas
- Monitore: CPU, memória, requisições/segundo, latência, erros 5xx
- Ferramentas: Prometheus + Grafana, ou Datadog/New Relic

### Alertas
- Configure alertas para:
  - Erro rate > 1%
  - Latência p95 > 500ms
  - Fila de uploads acumulada
  - Banco de dados CPU > 80%

---

## 7. Backup

### Banco de Dados
```bash
# Backup diário automatizado
pg_dump -h localhost -U postgres betooth > backup_$(date +%Y%m%d).sql

# Restore
psql -h localhost -U postgres betooth < backup_20260101.sql
```

### Storage (S3)
- Habilite versioning no bucket
- Configure lifecycle policies (ex: mover para Glacier após 90 dias)
- Configure cross-region replication para redundância

---

## 8. Escalabilidade

### Horizontal Scaling
- Use load balancer (AWS ALB, Nginx, Traefik)
- Escalar API: múltiplas instâncias do container Node.js
- Escalar workers: instâncias separadas para processamento de uploads

### Database
- Read replicas para queries de leitura
- Connection pooling (PgBouncer)
- Particionamento de tabelas grandes (history, entity_changes)

### Cache
- Redis cluster para alta disponibilidade
- Cache de queries frequentes no app

---

## Checklist Pré-Deploy

- [ ] Variáveis de ambiente configuradas
- [ ] Banco de dados migrado
- [ ] Redis conectado
- [ ] S3/storage configurado
- [ ] SSL/TLS ativo
- [ ] Rate limiting habilitado
- [ ] Logs configurados
- [ ] Backups automatizados
- [ ] APK/AAB assinado
- [ ] Screenshots e descrição prontos
- [ ] Política de privacidade publicada
- [ ] Termos de uso publicados

---

*Guia gerado em 11/05/2026*
