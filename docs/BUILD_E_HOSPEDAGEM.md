# Betooth - Build e Hospedagem Rápida

## ✅ Status Atual
- Página de download: `web/download/index.html` ✅ PRONTA
- QR codes dinâmicos ✅ GERADOS automaticamente
- Backend endpoints ✅ CONFIGURADOS
- **Falta:** Build APK + IPA, upload para servidor

---

## 🚀 Opção 1: Hospedagem Gratuita (Recomendada)

### Netlify (Mais Simples)

1. Acesse [netlify.com](https://netlify.com) e crie conta (grátis)
2. Instale o Netlify CLI:
```bash
npm install -g netlify-cli
```
3. Faça login:
```bash
netlify login
```
4. Deploy a pasta de download:
```bash
cd C:\Users\cliente\Projects\betooth
netlify deploy --prod --dir=web/download
```
5. O Netlify dará uma URL tipo: `https://betooth-abc123.netlify.app`

**Pronto!** Compartilhe esta URL. Os QR codes funcionam automaticamente.

---

## 🚀 Opção 2: Vercel (Alternativa)

1. Acesse [vercel.com](https://vercel.com) e crie conta
2. Instale Vercel CLI:
```bash
npm install -g vercel
```
3. Deploy:
```bash
cd C:\Users\cliente\Projects\betooth\web\download
vercel --prod
```

---

## 🚀 Opção 3: Servidor Próprio (VPS)

Se tiver um servidor com domínio próprio:

```bash
# No servidor
mkdir -p /var/www/betooth
cp -r web/download/* /var/www/betooth/
cp releases/android/app-release.apk /var/www/betooth/builds/
cp releases/ios/Betooth.ipa /var/www/betooth/builds/

# Configurar Nginx
sudo nano /etc/nginx/sites-available/betooth
```

Config Nginx:
```nginx
server {
    listen 80;
    server_name betooth.seudominio.com;
    root /var/www/betooth;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /builds/ {
        add_header Content-Disposition "attachment";
    }
}
```

---

## 📱 Como Buildar os Apps

### Android (APK)

**Requisitos:**
- Android Studio instalado
- SDK Android (API 21+)
- Flutter configurado

```bash
cd C:\Users\cliente\Projects\betooth

# Build APK
flutter build apk --release

# O APK estará em:
# build/app/outputs/flutter-apk/app-release.apk

# Copiar para pasta de releases
copy build\app\outputs\flutter-apk\app-release.apk releases\android\
```

### iOS (IPA)

**Requisitos:**
- Mac com Xcode
- Conta Apple Developer (free ou paga)
- Flutter configurado

```bash
cd ~/Projects/betooth

# Build IPA
flutter build ipa --release

# O IPA estará em:
# build/ios/ipa/Betooth.ipa

# Copiar para pasta de releases
cp build/ios/ipa/Betooth.ipa releases/ios/
```

**Para distribuir iOS sem App Store:**
1. **AltStore** (grátis, renova a cada 7 dias)
2. **Apple Developer Pago** ($99/ano, validade 1 ano)
3. **Enterprise** (conta corporativa)

---

## 🔗 URLs Importantes

Após hospedar, suas URLs serão:

| Recurso | URL |
|---------|-----|
| Página de download | `https://seu-dominio.com/download/` |
| Download Android | `https://seu-dominio.com/download/builds/app-release.apk` |
| Download iOS | `https://seu-dominio.com/download/builds/Betooth.ipa` |
| API Backend | `https://api.seu-dominio.com/api/v1/app-release/latest` |

---

## 📋 Checklist para Disponibilizar

- [ ] Buildar APK (`flutter build apk --release`)
- [ ] Copiar APK para `releases/android/`
- [ ] Buildar IPA (`flutter build ipa --release`) — requer Mac
- [ ] Copiar IPA para `releases/ios/`
- [ ] Hospedar página (Netlify/Vercel/servidor)
- [ ] Testar QR code com celular
- [ ] Testar download do APK
- [ ] Configurar backend em produção
- [ ] Testar pagamento VIP no Mercado Pago

---

## 💡 Dica Rápida

Se quiser **testar imediatamente** sem build:

1. Hospede a página no Netlify (passo 1 acima)
2. Os QR codes e botões aparecerão
3. Quando tiver o APK buildado, suba para `releases/android/`
4. Faça novo deploy
5. Pronto para compartilhar!

---

*Gerado em 11/05/2026*
