# Testando Webhooks do Mercado Pago Localmente

## Opção 1: ngrok (recomendado)

### Instalar ngrok

```bash
# Windows (via winget)
winget install ngrok

# Ou baixe diretamente: https://ngrok.com/download
```

### Expor o backend local

```bash
# 1. Inicie o backend
cd backend
npm run dev

# 2. Em outro terminal, exponha a porta 3333
ngrok http 3333
```

O ngrok vai mostrar uma URL pública, ex:
```
Forwarding  https://abc123.ngrok-free.app -> http://localhost:3333
```

### Configurar no painel MP (para teste)

Use a URL do ngrok no painel:
```
https://abc123.ngrok-free.app/api/v1/subscriptions/webhook
```

> **Importante:** Deixe `MP_WEBHOOK_SECRET` vazio no `.env` local para
> desativar a validação de assinatura durante testes.

---

## Opção 2: Simular manualmente com curl

Com o backend rodando localmente e `MP_WEBHOOK_SECRET` vazio:

```bash
# Simular notificação de pagamento aprovado
curl -X POST http://localhost:3333/api/v1/subscriptions/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "action": "payment.updated",
    "api_version": "v1",
    "data": { "id": "123456789" },
    "date_created": "2024-01-01T00:00:00Z",
    "id": 999999,
    "live_mode": false,
    "type": "payment",
    "user_id": "246148546"
  }'
```

Resposta esperada:
```json
{ "status": "ok", "data": { "received": true } }
```

> O backend vai tentar buscar o pagamento `123456789` na API do MP —
> vai retornar erro de busca, mas o endpoint responderá 200 (comportamento correto).

---

## Opção 3: Usar o simulador do painel MP

1. Acesse: https://www.mercadopago.com.br/developers/panel/webhooks
2. Após configurar a URL (ngrok ou produção), use o botão **"Enviar teste"**
3. O painel envia uma notificação real com assinatura válida

---

## Verificar logs

Com o backend rodando, os logs mostram:

```
# Webhook recebido e processado com sucesso:
INFO: Webhook processed { paymentId: "...", userId: "...", mpStatus: "approved" }

# Assinatura inválida:
WARN: Webhook signature mismatch { xSignature: "...", template: "..." }

# Erro ao buscar pagamento no MP:
WARN: Failed to fetch payment from MP { paymentId: "...", status: 401 }
```

---

## Fluxo completo de pagamento VIP

```
1. App Flutter → POST /api/v1/subscriptions/checkout
   ← retorna { checkoutUrl, preferenceId }

2. Usuário acessa checkoutUrl e paga no Mercado Pago

3. MP envia webhook → POST /api/v1/subscriptions/webhook
   - Backend valida assinatura (se MP_WEBHOOK_SECRET configurado)
   - Busca detalhes do pagamento na API do MP
   - Se status = "approved": cria/atualiza assinatura VIP no banco

4. App Flutter → GET /api/v1/subscriptions/me
   ← retorna { isVip: true, subscription: {...} }
```

---

## Checklist antes de ir para produção

- [ ] Backend deployado e respondendo em `/api/v1/health`
- [ ] `APP_URL` atualizado com a URL real do backend
- [ ] `MP_ACCESS_TOKEN` configurado com token de produção
- [ ] Webhook configurado no painel MP com a URL de produção
- [ ] `MP_WEBHOOK_SECRET` copiado do painel e adicionado às variáveis
- [ ] Teste manual via painel MP → botão "Enviar teste" → resposta 200
- [ ] Fazer um pagamento real de teste (R$ 0,01 ou use sandbox)
