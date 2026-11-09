# API service agent instructions

## Scope

These instructions apply to `services/api/`.

## Rules

- Keep endpoints explicit and easy to trace.
- Keep the starter service simple and dependency-light.
- Update `docs/api/openapi.yaml` when the HTTP surface changes.
- Prefer returning JSON with stable keys.
- Add tests for new behavior.
