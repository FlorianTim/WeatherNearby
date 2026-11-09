# Nothing recorded which parts of the app a Play submission depends on

- **Date:** 2026-08-26
- **Area:** Store readiness
- **Severity:** `friction`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

The in-app data-deletion path could have been deleted without anyone noticing until store review.

## Root cause

The release checklist covered build and signing but not the app surfaces a review inspects.

## Change made

A store-readiness section in the release checklist and its skill, naming the deletion path, the published legal pages, the absent price without a working billing adapter, and the development section.

## What would catch a recurrence

Manual, but now written down where the release process reads it.
