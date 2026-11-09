# The docs said `remove_backend.sh --with-packages` removes `packages/feature_flags`

- **Date:** 2026-08-26
- **Area:** Initialization
- **Severity:** `blocker`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

It removes `api_client` and `shared_models`; `feature_flags` is deliberately kept. Since 3.2.1 the app depends on it directly, so following the instruction breaks the build.

## Root cause

The documentation was written before 3.0.0 moved `feature_flags` out of the backend-removal set and was never revisited.

## Change made

Corrected the instruction and marked `feature_flags` non-removable in the classification.

## What would catch a recurrence

The script is the source of truth; the docs should be generated from it or checked against it.
