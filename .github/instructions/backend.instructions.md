---
name: Backend conventions
description: Rules for the Dart backend service
applyTo: "services/api/**/*.dart"
---
# Backend conventions

- Keep the HTTP surface small and explicit.
- Separate HTTP routing from business logic where the service grows.
- Return JSON objects with stable keys.
- Add at least one automated test for new behavior.
- Update `docs/api/openapi.yaml` when endpoints or payloads change.
- Prefer pure functions for domain logic when possible.
