# Betooth Simple Backend

Backend simplificado do Betooth usando SQLite (arquivo local) e sem dependências nativas problemáticas.

## Stack

- Node.js + Express + TypeScript
- SQLite (better-sqlite3)
- bcryptjs (JS puro, sem compilação nativa)
- JWT para autenticação

## Deploy no Render

1. Crie um novo Blueprint no Render
2. Selecione o repositório `betosouzabb-maker/Betooth`
3. Use o arquivo `backend-simple/render.yaml`
4. Preencha as variáveis de ambiente quando solicitado
5. Deploy

## Variáveis de Ambiente

- `JWT_ACCESS_SECRET` - Segredo para tokens de acesso
- `JWT_REFRESH_SECRET` - Segredo para tokens de refresh
- `ADMIN_MASTER_PASSWORD` - Senha master do admin
- `MP_ACCESS_TOKEN` - Token do Mercado Pago (opcional)
- `MP_WEBHOOK_SECRET` - Segredo do webhook MP (opcional)

## Endpoints

Todos os endpoints usam o prefixo `/api/v1`:

### Auth
- POST `/auth/register` - Cadastro
- POST `/auth/login` - Login
- POST `/auth/refresh` - Refresh token
- POST `/auth/logout` - Logout
- GET `/auth/me` - Perfil do usuário

### Music
- GET `/music/tracks` - Listar músicas
- GET `/music/tracks/:id` - Detalhes da música
- GET `/music/genres` - Listar gêneros
- GET `/music/search` - Buscar músicas

### Library
- GET `/library` - Biblioteca do usuário
- POST `/library/:trackId` - Adicionar à biblioteca
- DELETE `/library/:trackId` - Remover da biblioteca

### Playlists
- GET `/library/playlists` - Listar playlists
- POST `/library/playlists` - Criar playlist
- GET `/library/playlists/:id` - Detalhes da playlist
- POST `/library/playlists/:id/tracks` - Adicionar música
- DELETE `/library/playlists/:id/tracks/:trackId` - Remover música
- DELETE `/library/playlists/:id` - Deletar playlist

### Favorites
- GET `/library/favorites` - Favoritos
- POST `/library/favorites/:trackId` - Adicionar favorito
- DELETE `/library/favorites/:trackId` - Remover favorito

### History
- GET `/library/history` - Histórico
- POST `/library/history` - Registrar reprodução

### Downloads
- POST `/downloads/:trackId` - Baixar música
- GET `/downloads/quota` - Quota de downloads

### Subscriptions
- GET `/subscriptions/status` - Status da assinatura
- POST `/subscriptions/create` - Criar assinatura (mock)
- POST `/subscriptions/cancel` - Cancelar assinatura
- POST `/subscriptions/webhook` - Webhook do Mercado Pago

### Admin
- GET `/admin/stats` - Estatísticas
- GET `/admin/users` - Listar usuários
- PATCH `/admin/users/:id/status` - Atualizar status
- POST `/admin/tracks` - Adicionar música
- DELETE `/admin/tracks/:id` - Remover música
- GET `/admin/notifications` - Notificações
- POST `/admin/notifications` - Enviar notificação
- POST `/admin/notifications/:id/read` - Marcar como lida
