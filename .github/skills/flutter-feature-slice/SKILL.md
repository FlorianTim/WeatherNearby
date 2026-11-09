# Flutter Feature Slice

Use this skill when adding a new feature to the Flutter app.

## Objective

Create a new feature under `apps/mobile_app/lib/features/<feature-name>/` with a feature-first layout.

## Steps

1. Create:
   - `presentation/`
   - `application/`
   - `data/`
   - `domain/`
2. Keep UI widgets in `presentation/`.
3. Keep use cases or controllers in `application/`.
4. Keep repositories, DTOs, and data sources in `data/`.
5. Keep entities and business rules in `domain/`.
6. Add at least one test for non-trivial logic.
7. Update docs if the feature changes architecture or runtime behavior.
