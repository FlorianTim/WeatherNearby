---
name: codegen
description: Regenerate all generated sources (Drift, Freezed, Riverpod AND
  l10n). Use after editing tables, models, providers or ARB files, or when
  the analyzer reports missing *.g.dart / AppLocalizations.
---

Run `bash scripts/dev/codegen.sh` (Windows: `pwsh scripts/dev/codegen.ps1`),
which calls `melos run codegen`.

- Runs build_runner (Drift/Freezed/Riverpod) **and** `flutter gen-l10n`.
- The l10n step is easy to forget — always use this wrapper rather than a
  bare `dart run build_runner build`, otherwise generated localizations go
  stale and CI fails on codegen drift.
- Commit the regenerated files together with the source change.
