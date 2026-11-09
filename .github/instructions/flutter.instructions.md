---
name: Flutter conventions
description: Rules for Flutter app and Flutter packages
applyTo: "apps/mobile_app/**/*.dart,packages/design_system/**/*.dart"
---
# Flutter conventions

- Organize app code by feature first, then by layer inside the feature.
- Keep `app/` for bootstrapping, router, theme, and dependency wiring.
- Put feature-independent UI building blocks in `packages/design_system`.
- Prefer stateless widgets until mutable state is clearly needed.
- Keep widgets small and composable.
- Avoid direct networking code inside presentation widgets.
- Use English names for types, methods, variables, and files.
- Add or update tests for non-trivial logic.

## Architecture and dependencies

- Before changes, review existing Flutter structure and conventions.
- Do not introduce a new state management library without an existing project decision or ADR.
- If Riverpod, BLoC, Provider, or another solution is already used, follow that choice.
- Do not mix state management approaches without an ADR.
- Platform code (Android/iOS-specific) should be isolated and documented.
- Do not add packages without justification and ideally a spec or ADR reference.

## Testing

- Add widget, unit, or integration tests when changes affect behavior.
- Use `flutter analyze` and `flutter test` to validate changes.
- Test expectations should be part of the story or task that drives the change.
