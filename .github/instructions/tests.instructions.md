---
name: Testing conventions
description: Rules for tests across all project types
applyTo: "**/test/**/*.dart,**/test_driver/**/*.dart,**/integration_test/**/*.dart"
---
# Testing conventions

- Every code change with functional impact should add or update tests.
- Respect the existing test structure and conventions.
- Tests should cover acceptance criteria from the relevant story.
- Do not delete tests to make CI pass — fix the underlying issue instead.

## Flutter and Dart

- Use `flutter test` for widget and unit tests in Flutter packages.
- Use `dart test` for pure Dart packages and backend services.
- Use `flutter analyze` / `dart analyze` before considering work complete.
- Coverage reports can be generated via melos: `melos run test`.

## When tests cannot run

- If tests are not executable (missing tooling, environment constraints), document why in the PR.
- If automated tests are not meaningful for the change, document manual verification steps.

## Documentation and workflow changes

- Documentation changes should be checked for link consistency and obvious formatting errors.
- YAML files should be syntactically valid.
- CI should respect existing project structure and not fail due to incorrect assumptions.
