# "Remove the example-app entries" under `docs/delivery/` does not say which ones

- **Date:** 2026-08-27
- **Area:** Initialization
- **Severity:** `papercut`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

The row reads: `docs/delivery/implementation-plans/`, `docs/delivery/stories/`
→ *remove the example-app entries; the app writes its own*. What is actually
there:

| Entry | Belongs to |
|---|---|
| `implementation-plans/0000-shared-foundations.md` | the shell |
| `implementation-plans/0001-todo-reference-app.md` | the example app |
| `implementation-plans/0002-settings-and-app-shell.md` | the shell |
| `stories/0000-shared-foundations/` (7 stories) | the shell |
| `stories/0002-settings-and-app-shell/` | the shell |
| `reviews/2026-08-25-template-readiness-todo-reference-app.md` | the example app |

One of six is an example-app plan. The instruction reads as "clear these
folders" and two-thirds of what it would clear is the delivery history of the
shell the app inherits — the same material `docs/product/specs/0005`–`0007`
is explicitly kept for. `docs/delivery/reviews/` is not mentioned at all,
though it holds an example-app review.

## Root cause

The row was written when `docs/delivery/` held the todo reference app and
nothing else. The shell's own plan and stories landed in 3.2.1 next to it and
the row was not revisited.

## Change made

The entries are named individually — one plan and one review go, the shell's
plan and stories stay — and `docs/delivery/reviews/` is classified.

## What would catch a recurrence

Naming entries rather than folders wherever a folder holds both kinds. It is
the same failure as the shell-vs-example split everywhere else in this table:
a folder is not a classification unit once two owners share it.
