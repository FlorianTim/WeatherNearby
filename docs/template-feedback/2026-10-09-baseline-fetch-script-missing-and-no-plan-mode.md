# `fetch_engineering_release.py` is not in the template, and it cannot show a plan

- **Date:** 2026-10-09
- **Area:** Baseline / tooling
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work); baseline 1.5.2 -> 1.6.0
- **Status:** worked around

## Observed

`check_update.py` ends with `python scripts/fetch_engineering_release.py --tag v1.6.0 ...`, but the template has no such script (it exists only in `lumbrecode-engineering/scripts/`). The task also says to read the plan before anything is written; the script has no dry-run and calls `apply_baseline.py --apply` straight away. The plan is only visible by downloading the release zip by hand and running its `apply_baseline.py` without `--apply`.

## Workaround

Copied the script from `lumbrecode-engineering` into `scripts/`, downloaded the zip into a scratch directory, ran `apply_baseline.py --profile flutter --target .` (plan only), then `--apply --force` (see the CRLF entry).

## Smallest generic change

The baseline should ship the fetch script itself (the profile's file list), and the script should take `--plan` (pass-through without `--apply`) and `--force`. `check_update.py` should print `--plan` first.

## Check that would catch a recurrence

`check_update.py` fails (not just warns) when the script it advertises is not present.
