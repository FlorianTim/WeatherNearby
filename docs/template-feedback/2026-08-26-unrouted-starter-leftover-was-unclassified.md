# `lib/features/home/` was an unrouted leftover of the original starter scaffold, classified nowhere

- **Date:** 2026-08-26
- **Area:** Initialization
- **Severity:** `papercut`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

Unrouted, unclassified code is exactly what makes an initializer guess wrong about what to delete.

## Root cause

It was never removed when the greeting page took over as the demo screen, and nothing referenced it, so nothing failed.

## Change made

Classified as example-app surface.

## What would catch a recurrence

The coverage check above catches this class of gap.
