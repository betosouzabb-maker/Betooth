# Deploy no Render.com — Guia Rápido

## Link de Deploy com 1 Clique

**Clique aqui para fazer o deploy:**

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/betosouzabb-maker/Betooth)

Ou acesse diretamente:
```
https://render.com/deploy?repo=https://github.com/betosouzabb-maker/Betooth
```

---

## O que o `render.yaml` já configura automaticamente

Ao clicar no link acima, o Render vai criar:

| Recurso | Nome | Plano |
|---|---|---|
| Web Service (Node.js) | `betooth-backend` | Free |
| PostgreSQL | `betooth-db` | Free (expira em 90 dias) |
| Redis / Key-Value | `betooth-redis` | Free |

Variáveis configuradas automaticamente:
- `DATABASE_URL` — conecta ao banco criado
- `REDIS_URL` — conecta ao Redis criado
- `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` — geradas automaticamente
- `ADMIN_MASTER_PASSWORD` — gerada automaticamente
- Todas as configs de rate limiting, porta, etc.

---

## Após o deploy: variáveis que precisam ser preenchidas manualmente

No painel do Render → seu serviço `betooth-backend` → **Environment**, adicione:

| Variável | Onde pegar |
|---|---|
| `S3_BUCKET` | Nome do seu bucket AWS S3 ou Cloudflare R2 |
| `S3_ACCESS_KEY_ID` | AWS IAM ou Cloudflare R2 API Keys |
| `S3_SECRET_ACCESS_KEY` | AWS IAM ou Cloudflare R2 API Keys |
| `S3_ENDPOINT` | Só para R2: `https://<account-id>.r2.cloudflarestorage.com` |
| `MP_ACCESS_TOKEN` | Mercado Pago → credenciais de produção |
| `MP_WEBHOOK_SECRET` | Mercado Pago → configurar webhook → `https://betooth-backend.onrender.com/api/v1/payments/webhook` |

---

## Passo a passo (se preferir fazer manualmente)

1. Acesse https://render.com e faça login (ou crie conta gratuita)
2. Clique em **"New +"** → **"Blueprint"**
3. Conecte ao GitHub e selecione o repo `betosouzabb-maker/Betooth`
4. Render detecta o `render.yaml` automaticamente
5. Clique em **"Apply"**
6. Aguarde ~5 minutos para o build terminar
7. Preencha as variáveis S3 e Mercado Pago no painel

---

## URL do backend após deploy

```
https://betooth-backend.onrender.com
```

Endpoint de saúde:
```
GET https://betooth-backend.onrender.com/api/v1/health
```

---

## Avisos importantes

- **Plano gratuito do Render**: o serviço web "dorme" após 15 minutos sem requisições
  - Primeira requisição após inatividade demora ~30 segundos (cold start)
  - Para evitar isso, faça upgrade para o plano Starter (~$7/mês)
- **PostgreSQL gratuito**: expira automaticamente após **90 dias**
  - Faça backup dos dados antes ou upgrade para plano pago
- **Redis gratuito**: disponível no plano Free sem expiração de dados, mas com limites de memória
