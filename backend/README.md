# Backend (Node.js) — optional

Optional Node.js/JavaScript backend base for LumbreCode Flutter apps.
This directory is a **starting point**, not a finished product. Apps that do
not need a backend simply ignore it (see `backend_enabled` in the app spec).

> The repository also contains a minimal Dart/Shelf service under
> `services/api/`. Pick ONE backend per app and remove the other during app
> initialization (the template initializer asks for `backend_enabled` and the
> backend flavor).

## Stack

- Node.js 22+ (ESM, no build step)
- [Express 5](https://expressjs.com) — HTTP server
- [Zod](https://zod.dev) — request/env validation
- `node:test` — built-in test runner (no extra framework)
- ESLint + Prettier

## Commands

```bash
npm install
npm run dev           # start with file watching
npm start             # start
npm test              # run tests (node --test)
npm run lint          # eslint
npm run format:check  # prettier check
npm audit             # dependency audit
```

## Configuration

Copy `.env.example` to `.env` and adjust. `.env` is gitignored — never commit
real values. All environment variables are validated in `src/config.js`.

## Security basics

- Validate every request body with a Zod schema (see `POST /v1/echo`).
- `x-powered-by` is disabled; JSON body size is limited.
- Never log tokens, secrets, or personal data.
- Only expose client-safe values via `/v1/config`.
- Follow the [OWASP API Security Top 10](https://owasp.org/API-Security/).

## Docker / deployment

No Dockerfile is included yet on purpose — add one per app when deployment is
decided. A minimal production image is typically:

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src
USER node
CMD ["node", "src/server.js"]
```
