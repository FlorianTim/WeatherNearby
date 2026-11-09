# Review: template initializer, `dry-run` mode

## Metadata

- **Subject:** `.github/agents/template-initializer.agent.md`, mode `dry-run`
- **Binding table:** `docs/operations/template-initialization.md` →
  "What is kept, adapted and replaced"
- **Input:** `drafts/init/spec/EXAMPLE-dry-run-fixture.md` (Water Log)
- **Template version:** 3.2.1 · **Commit:** `d993d33`
- **Reviewer:** template maintenance
- **Date:** 2026-08-27

## Why this exists

The keep/replace classification introduced in 3.2.1 had never been executed —
only read. This is the first rehearsal: derive the deletion list the way the
initializer would, then check it against classifications 1 and 2 (template
infrastructure and app shell), which the agent file says must never appear in
it.

Nothing in the repository was modified by the rehearsal itself. `dry-run`
changes nothing by definition, and the fixture plus this report are the only
files it produced.

## Provenance recorded first

Per the agent's `audit`/`apply` preconditions, before anything else:

| | |
|---|---|
| Template `VERSION` | `3.2.1` |
| `git rev-parse --short HEAD` | `d993d33` |
| Date | 2026-08-27 |

## Input

The brief is `drafts/init/spec/EXAMPLE-dry-run-fixture.md`. The OpenSpec entry
derived from it — not committed, since this is a rehearsal and not a real app:

```yaml
spec_version: 1

company:
  name: LumbreCode
  domain: LumbreCode.de
  base_package: de.lumbre.code

app:
  app_name: "waterlog"
  app_display_name: "Water Log"
  app_slug: "waterlog"
  short_description: "Records how much water you drink during the day."
  primary_platforms: [android]

backend:
  backend_enabled: false
  backend_flavor: node

features:
  core_features:
    - "Today's intake: add a drink in one tap, see the day's total"
    - "The last seven days: one row per day with its total"

privacy_requirements:
  - privacy-by-default, no analytics or crash reporting without opt-in
  - no external fonts or CDNs without a documented decision
  - no personal data in logs

security_requirements:
  - no secrets in the repository; use .env.example with documented names
  - follow OWASP MASVS (mobile) and OWASP API Security Top 10 (backend)

splash:
  splash_screen_app_name: "Water Log"
  replace_lottie_placeholders: false

initialization:
  replace_todo_app: true
```

Against `openspec/README.md` → "Validation checklist": all required fields
present, `waterlog` matches `^[a-z][a-z0-9_]*$`, not a reserved word, backend
decided, `replace_todo_app` explicit, splash name set, privacy and security
requirements reviewed. The entry passes.

## The deletion list, as paths

This is the list the agent's `dry-run` mode is supposed to produce and a human
is supposed to read. It is a list of paths, never a folder sweep.

### Example feature (classification 3)

| Path | Count |
|---|---|
| `apps/mobile_app/lib/features/todos/` | 17 files |
| `apps/mobile_app/lib/features/greeting/presentation/greeting_page.dart` | 1 |
| `apps/mobile_app/lib/features/home/presentation/home_page.dart` | 1 |
| `apps/mobile_app/test/features/todos/` | 4 files |
| `openspec/apps/todoapp.openspec.yaml` | 1 |
| `openspec/apps/todo.openspec.yaml` | 1 — **not in the table**, see F4 |

### Documentation (classification 7)

| Path | Note |
|---|---|
| `docs/product/specs/0001-task-and-list-domain/` … `0004-jscalendar-interoperability/` | example-app feature specs |
| `docs/ideas/` | 6 files, template-internal analysis |
| `docs/delivery/implementation-plans/0001-todo-reference-app.md` | example-app plan |
| `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md` | **not in the table**, see F5 |
| `drafts/` except `drafts/init/` | `README.md`, `Verbesserungen.txt`, `archive/`, `assets/`, `experiments/`, `notes/`, `prompts/` |

### l10n keys (classification 4)

16 keys in both `app_de.arb` and `app_en.arb`, of 129 total:

```
currentTime  greetMe  greeting  todoCreate  todoCreateTitle  todoDelete
todoDescriptionLabel  todoEmpty  todoErrorLoading  todoRequired  todoRetry
todoStatusCompleted  todoStatusInProgress  todoStatusPending  todoTitleLabel
todosTitle
```

### Not deleted, deliberately

`packages/` in full including `feature_flags`; all of `lib/core/`; every shell
feature; `docs/architecture/{contracts,patterns}/`; `docs/known-issues.md`;
`docs/operations/`; `docs/product/specs/0005`–`0007`; `drafts/init/`.

## The check the dry-run exists for

> If the deletion list contains anything from classification 1 or 2 — any
> shell feature, any `lib/core/` folder other than the todo tables,
> `packages/feature_flags`, or a route in `lib/app/router/routes.dart` — the
> dry-run is wrong.

**The list passes that check.** No classification-1 or -2 path is in it.

**And the check is not sufficient.** Executing the list as written leaves a
repository that does not compile, because five call sites in classification-2
files reference the classification-3 code being deleted. The rule looks only
at what is *in* the list, never at what the list *breaks*.

| Referencing file | Classification | Reference |
|---|---|---|
| `lib/core/database/app_database.dart:4,8` | 2 — keep | imports `TodoItems` from `lib/features/todos/data/tables/` and declares `@DriftDatabase(tables: [TodoItems])` |
| `lib/core/startup/startup_providers.dart:3,35,40` | 2 — keep | imports `todoListProvider`; the `todo-list` startup task reads it |
| `lib/app/router/app_router.dart:200` | 2 — extend | the **privacy** route's `onDeleteAllData` calls `ref.invalidate(todoListProvider)` |
| `test/core/database/wipe_all_data_test.dart:19` | 2 — keep | inserts through `TodoItemsCompanion` |
| `test/core/database/migration_test.dart:23,50,71` | 2 — keep | its schema-v1 snapshot **is** the todo table |

The third one is the one that matters most: `onDeleteAllData` is the in-app
data-deletion path Google Play requires, and it is the single thing the
classification is most protective about. It has a hard dependency on the
example feature, and nothing said so.

The fifth fails softer than the rest — raw SQL plus `database.todoItems`, so
it breaks at the generated accessor rather than at an import. It also shows
why the obvious reference check is too narrow: grepping for `features/todos`
or `TodoItems` misses it. The check now greps case-insensitively for
`todo|greet` and reports **files**, not lines. In 3.2.1 that is twelve:

```
lib/app/app_identity.dart                       lib/app/router/app_router.dart
lib/app/router/routes.dart                      lib/core/database/app_database.dart
lib/core/startup/startup_providers.dart         test/core/database/migration_test.dart
test/core/database/wipe_all_data_test.dart      test/features/about/about_page_test.dart
test/features/splash/startup_error_page_test.dart
test/smoke_test.dart                            integration_test/app_flow_test.dart
integration_test/app_screenshots_test.dart
```

Every one needs a decision, and the twelve happen to cover F1, F2 and F3 in a
single command.

## Findings

Written up one file per problem in `docs/template-feedback/`:

| | Severity | Summary |
|---|---|---|
| F1 | `blocker` | The shell depends on the example feature in four places; deleting by the table's paths yields a repository that does not compile |
| F2 | `friction` | Three shell tests assert the template's own web slug, so "the shell's tests still pass" cannot hold after the mandated `AppIdentity.webSlug` rewrite |
| F3 | `papercut` | Example-app tests live in files the table never classifies (`test/smoke_test.dart`, `integration_test/app_flow_test.dart`) |
| F4 | `papercut` | `openspec/apps/` holds two example entries; the table names one |
| F5 | `papercut` | "remove the example-app entries" under `docs/delivery/` is ambiguous — two of the three plans describe the shell |

## What changed as a result

- `docs/operations/template-initialization.md` — the stale
  "todo tables in `lib/core/database/`" row replaced by the four real call
  sites and a rewire step; the unclassified paths from F3–F5 classified.
- `.github/agents/template-initializer.agent.md` — mirrors it, and `dry-run`
  now has to report the call sites, not only the paths.

## Not changed, on purpose

The coupling itself. `lib/core/database/app_database.dart` importing a table
out of `lib/features/` is a layering inversion, and the `todo-list` startup
task and the privacy invalidation are demonstrative by design — they show a
derived app *where* its own provider goes. Removing them would remove the
example; rewiring them is a one-line edit each once the initializer is told to
do it. Whether `app_database.dart` should own its tables instead is a separate
question, recorded in F1 as a follow-up.

## Risks

- The rehearsal is still paper. It derives the list and reads the call sites;
  it does not delete anything and does not compile the result. A real `apply`
  against a scratch clone would catch a class of problem this cannot — the
  generated `*.g.dart` fallout in particular.
- The fixture is deliberately minimal: one entity, no backend, no permissions,
  no branding. The backend removal path (`remove_backend.sh`), the permission
  list on `PrivacyPage` and the Lottie/icon replacement were not exercised.

## Follow-up tasks

- [ ] Run `apply` once against a throwaway clone and let `melos run ci` judge
      it. Everything above is inspection.
- [ ] Decide whether `AppDatabase` should own its table definitions instead of
      importing them from a feature (F1).
- [ ] Give the shell tests their identity expectations from `AppIdentity`
      rather than the literal `todo-app` (F2).
