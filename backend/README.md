# Betooth Backend

Backend base em `Node.js + Express + TypeScript`, com Prisma para PostgreSQL, Redis para cache/fila/sessões e estrutura modular pronta para evolução.

## Stack

- Express 5
- TypeScript em modo `strict`
- Prisma ORM
- Redis com `ioredis`
- BullMQ
- Pino para logging estruturado
- Zod para validação

## Estrutura

- `src/app.ts`: configuração principal do Express
- `src/server.ts`: bootstrap do servidor e shutdown gracioso
- `src/modules/*`: módulos por domínio
- `src/common/*`: middlewares, tipos e utilitários compartilhados
- `src/infra/*`: integrações com Prisma, Redis, S3 e fila
- `prisma/schema.prisma`: schema completo do banco

## Scripts

- `npm run dev`
- `npm run build`
- `npm run start`
- `npm run typecheck`
- `npm run migrate`
- `npm run seed`

## Como usar

1. Copie `backend/.env.example` para `backend/.env`
2. Ajuste as variáveis de ambiente
3. Execute `npm install`
4. Execute `npm run typecheck`
5. Execute `npm run dev`

## Endpoints iniciais

- `GET /api/v1/health`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `GET /api/v1/auth/me`
- `GET /api/v1/users`
- `GET /api/v1/music/tracks`

## Observações

- O código está preparado para PostgreSQL e Redis, mas não exige que os serviços estejam ativos para compilar.
- O seed atual é um placeholder seguro e pode ser expandido quando o banco estiver disponível.