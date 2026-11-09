# The file classification put `lib/features/settings/` under "Todo example app" and did not mention the app shell at all

- **Date:** 2026-08-26
- **Area:** Initialization
- **Severity:** `blocker`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

An initializer following it literally deletes the settings hub, the privacy page, the intro, the help pages and the Pro page. The privacy page is the in-app data-deletion path Google Play requires.

## Root cause

The classification listed paths by feature folder without a rule for what the default is, so anything unnamed read as "unclear, probably removable".

## Change made

Canonical keep/adapt/replace table with *keep* as the default, every path under `apps/mobile_app/lib/` classified, and deletion by explicit path rather than folder sweep.

## What would catch a recurrence

A check that every directory under `lib/` appears in the classification table.
