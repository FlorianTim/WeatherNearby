# A baseline sync reports a conflict on a file that differs only in line endings

- **Date:** 2026-10-09
- **Area:** Baseline / Windows
- **Severity:** `friction`
- **Template version:** 3.2.1 (commit f613988 plus uncommitted work); baseline 1.5.2 -> 1.6.0
- **Status:** worked around

## Observed

`apply_baseline.py` reported `CONFLICT .github/renovate.json5` ("modified locally") and refused to apply. The working-tree file had CRLF line endings (`core.autocrlf=true`, index and HEAD are LF); the baseline's file is LF; content is identical (`diff` after `tr -d ''` is empty). The hash comparison is byte-wise, so every managed text file on a Windows checkout is a potential false conflict, and it only surfaced for this one because the others were not yet CRLF in the working tree.

## Workaround

Verified the files are identical modulo CRLF, then ran with `--force`. The result is an LF file that git sees as unchanged.

## Smallest generic change

`apply_baseline.py` compares and hashes after normalising line endings (or treats CRLF-only differences as UNCHANGED). Alternatively the baseline ships `.gitattributes` with `eol=lf` for managed files.

## Check that would catch a recurrence

A test in `lumbrecode-engineering` that applies the baseline to a CRLF copy of a managed file and expects UNCHANGED.
