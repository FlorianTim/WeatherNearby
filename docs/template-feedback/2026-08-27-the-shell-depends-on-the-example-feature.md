# The app shell depends on the example feature, so deleting the example by the book leaves a repository that does not compile

- **Date:** 2026-08-27
- **Area:** Initialization
- **Severity:** `blocker`
- **Template version:** 3.2.1
- **Status:** documented in 3.2.1; the coupling itself is a follow-up

## Observed

The first `dry-run` rehearsal
(`docs/delivery/reviews/2026-08-27-initializer-dry-run.md`) produced a deletion
list that passes the rule the dry-run exists for — no classification-1 or -2
path is in it — and would still break the build. Five call sites in files
classified **keep** reference the example feature being deleted:

| Referencing file | Reference |
|---|---|
| `lib/core/database/app_database.dart:4,8` | imports `TodoItems` from `lib/features/todos/data/tables/`, declares `@DriftDatabase(tables: [TodoItems])` |
| `lib/core/startup/startup_providers.dart:3,35,40` | imports `todoListProvider`; the `todo-list` startup task reads it |
| `lib/app/router/app_router.dart:200` | the **privacy** route's `onDeleteAllData` calls `ref.invalidate(todoListProvider)` |
| `test/core/database/wipe_all_data_test.dart:19` | inserts through `TodoItemsCompanion` |
| `test/core/database/migration_test.dart:23,50,71` | its schema-v1 snapshot **is** the todo table |

The third one is the worst case the classification is meant to prevent:
`onDeleteAllData` is the in-app data-deletion path Google Play requires. It
survives the deletion list and breaks anyway.

## Root cause

Two mistakes, one on top of the other.

The table said **"todo tables in `lib/core/database/` → replace"**. There are
no todo tables there and there never were in 3.2.1: the table lives in
`lib/features/todos/data/tables/todo_table.dart` and `AppDatabase` imports it
out of the feature. An initializer following that row looks for files that do
not exist, finds nothing, and moves on satisfied.

And the safety rule is phrased as a membership test — "if the deletion list
contains a shell path, the dry-run is wrong". It asks what is *in* the list. It
never asks what the list *breaks*. A classification table cannot answer that
question at all; only a reference check can.

## Change made

- The stale row is replaced by the four real call sites, each with what has to
  happen to it.
- `dry-run` now has to report the reference check, not only the paths, and
  `apply` has a rewire step before the deletion step.
- The Play-Store consequence is stated where the coupling is, not only where
  the privacy page is described.

## What would catch a recurrence

The reference check itself, now part of `dry-run`: grep the shell for the
feature being replaced and require every hit to have a decision. It is
mechanical and it would have caught all five.

The narrow version of that grep does not. Searching for `features/todos` or
`TodoItems` misses `migration_test.dart`, which reaches the table through raw
SQL and the generated `database.todoItems` accessor. The check is therefore
case-insensitive on `todo|greet` and reports files rather than lines — twelve
of them in 3.2.1, which is a list a human can actually read.

## Follow-up

Whether `AppDatabase` should own its table definitions instead of importing
them from a feature. `lib/core/` importing `lib/features/` is a layering
inversion independent of initialization — it just happens to surface here
first. The startup task and the privacy invalidation are different: they are
demonstrative on purpose, showing a derived app where its own provider goes.
Those stay and get rewired.
