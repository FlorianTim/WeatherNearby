# Creating a new app from this template

Publisher: **LumbreCode** (LumbreCode.de) — package schema:
`de.lumbre.code.<app_slug>`.

## Overview

1. Create the repo via GitHub **"Use this template"**.
2. Drop everything the app is built from into **`drafts/init/`** — the
   description, notes, mockups, icons, resources. See
   `drafts/init/README.md`. This is the initializer's input, and the one
   part of `drafts/` that is read rather than ignored.
3. Write the app spec: copy `openspec/templates/app.openspec.yaml` to
   `openspec/apps/<app_slug>.openspec.yaml` and fill in all fields
   (checklist in `openspec/README.md`).
4. Run the initializer agent
   (`.github/agents/template-initializer.agent.md`) in this order:
   `audit` → `dry-run` → review → `apply`.
5. Verify with `melos run ci`.
6. Retire `drafts/init/` once `drafts/init/processed.md` shows everything
   processed.

## Large specifications: plan & spec phase first

When the input is a large requirements document (or a collection of texts
and images, e.g. dropped into `drafts/`), do NOT initialize or implement
directly from it. A plan & spec phase comes first:

1. **Plan phase** — read the full requirements material, identify the app
   identity (name, slug, platforms, backend need) and list all requested
   features. Classify each feature as **key feature** (needed for a usable
   first version) or **follow-up feature**.
2. **Spec phase** — split the requirements into normative specs:
   - exactly one OpenSpec entry `openspec/apps/<app_slug>.openspec.yaml`
     (app identity + `core_features` = the key features), and
   - one feature spec per feature under
     `docs/product/specs/<NNNN-feature-name>/` (see the spec-first workflow
     in `AGENTS.md`). A single requirements file typically results in
     **multiple** feature specs.
3. **Review gate** — the plan and the specs are reviewed/approved before any
   code changes. The original requirements document stays in `drafts/` as
   non-normative input; only the specs are binding.
4. **Incremental build** — initialize the app base via the initializer
   (`audit` → `dry-run` → `apply`), then implement the feature specs one by
   one: key features first, each feature on its own branch with small
   Conventional Commits and its own PR. Follow-up features go through the
   normal spec-first workflow afterwards.

## Bootstrap safety

> **⚠️ Never run `flutter create . --overwrite` inside `apps/mobile_app`.**
> It overwrites `pubspec.yaml` (all dependencies gone), `lib/main.dart`,
> `test/widget_test.dart`, `README.md`, `analysis_options.yaml` and
> `.gitignore`. The bootstrap scripts (`scripts/bootstrap_*.sh|ps1`) are safe:
> they run `flutter create` in a temp directory and copy **only the platform
> folders** (`android/`, `ios/`, `web/`, `linux/`) into the project. Always
> use the scripts — never call `flutter create` in the app folder by hand.

## What is kept, adapted and replaced

> **Canonical table.** `.github/agents/template-initializer.agent.md`
> mirrors it; if the two disagree, this one wins.

Initialization is a **careful replacement of the example feature**, not a
reset of `apps/mobile_app/`. The default for every path is *keep*.

| Path | On `replace_todo_app: true` | Why |
|---|---|---|
| `lib/features/todos/` | **replace** | The example feature |
| `lib/features/greeting/` | **replace** | The example home screen — but its app-bar actions open `/settings` and `/about`; the new main screen must carry them |
| `lib/features/todos/data/tables/todo_table.dart` | **replace — part of the feature above** | Where the example schema actually lives. **Not** in `lib/core/database/`, which is what this table claimed until 3.2.1: `AppDatabase` imports the table out of the feature, so replacing it means rewiring the shell. See "The shell references the example feature" |
| `lib/features/settings/` | **keep** | Settings hub + debug diagnostics |
| `lib/features/onboarding/` | **keep** | First-start intro |
| `lib/features/help/` | **keep** | Manual and FAQ pages |
| `lib/features/privacy/` | **keep** | Privacy page and both destructive actions |
| `lib/features/monetization/` | **keep** | Purchase seam, entitlement cache, Pro page |
| `lib/features/about/` | **keep** | Links, support mailboxes, licences, version |
| `lib/features/splash/` | **adapt** | Company phase stays; app phase gets the new name |
| `lib/features/home/` | **replace** | Unrouted leftover of the original starter scaffold; goes with the example app |
| `lib/core/` (all of it) | **keep** | Database shell, settings register, startup coordinator, permission flow, plugin seams, error buffer, storage, time seams |
| `lib/core/database/app_database.dart`, `lib/core/startup/startup_providers.dart` | **keep, rewire** | Both name the example feature; see "The shell references the example feature" |
| `lib/app/{app,bootstrap}.dart`, `lib/app/providers/` | **keep** | App root, startup bootstrap, locale and theme notifiers |
| `lib/core/menu/`, `lib/app/menu/`, `lib/app/developer_tools.dart` | **keep** | The menu bar and its keys (spec 0008, ADR-0016). **Adapt** the entries in `lib/app/menu/app_menus.dart`: the Go to entry for `AppRoutes.todos` points at the example feature and must name the new app's main screen |
| `lib/app/app_identity.dart` | **rewrite** | `displayName` and `webSlug` are per-app; everything else derives from them |
| `lib/app/router/routes.dart` | **extend** | Add app routes; never remove a shell route |
| `lib/app/router/app_router.dart` | **extend** | Rewire the example routes; keep the shell routes and the splash's three-way destination |
| `packages/feature_flags` | **keep** | Direct dependency of `lib/features/monetization/` since 3.2.1 |
| `task_interchange` dependency in `apps/mobile_app/pubspec.yaml`, `test/interop/`, `FLUTTER_LIBRARIES_TOKEN` in `ci-mobile.yml` | **keep** | A tag-pinned dependency on `flutter-libraries` (ADR-0017), not an in-repo package and not part of the example feature. `replace_todo_app: true` does not remove it; the app bumps the tag. Make sure the new repository has the `FLUTTER_LIBRARIES_TOKEN` secret (`docs/operations/local-library-development.md`) |
| `pubspec_overrides.yaml` | **never create in a commit** | Local cross-repository development only; ignored by `.gitignore` |
| `packages/api_client`, `packages/shared_models` | removable with `remove_backend.sh --with-packages` | Only exist to serve a backend |
| `assets/help/*.md` | **generated — never edit** | Rendered from `docs/public-site/`; edit the source, then re-render |
| `docs/public-site/` | **rewrite the content, keep the structure** | One source for the published site and the bundled in-app help |
| `docs/public-site/screenshots.yaml` | **rewrite** | Which screenshots the guides may reference. Keep them required: a missing image should fail the build, not ship a caption-only guide |
| `intro*`, `privacyLocalBody` l10n keys | **rewrite** | Per-app copy |
| all other shell l10n keys | **keep** | `settings*`, `help*`, `pro*`, `about*`, `diagnostics*`, `startup*`, `permission*`, `common*`, `link*` |
| `todo*`, `greet*`, `greeting`, `currentTime` l10n keys | **delete** | Example-app copy — but see "remove less" below |
| `test/features/todos/` | **delete** | The example feature's own tests |
| `test/smoke_test.dart` | **edit** | Five shell tests and one greeting test share the file; drop the greeting test, keep the rest |
| `integration_test/app_flow_test.dart` | **edit** | The flow is `splash -> settings -> greeting`; re-point its last leg at the new app's main screen |
| `test/core/database/{migration,wipe_all_data}_test.dart` | **edit** | Shell tests written against the todo schema; rewrite them against the new one — do not delete them, `wipeAllData()` is the privacy page's contract |
| `test/features/{settings,onboarding,help,privacy,monetization,about,splash}/`, `test/a11y/`, `test/core/` (rest), `test/support/` | **keep** | The shell's own suites |
| `docs/architecture/{contracts,patterns}/`, `docs/known-issues.md`, `docs/operations/` | **keep** | The rules the app inherits |
| `docs/product/specs/0005`–`0008` | **keep** | They specify the shell the app inherits (0008: build flavors and the menu) |
| `docs/product/specs/0001`–`0004`, `docs/ideas/` | **delete** | Example-app and template-internal material |
| `docs/delivery/implementation-plans/0001-todo-reference-app.md`, `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md` | **delete** | The example app's plan and its review |
| `docs/delivery/implementation-plans/{0000,0002}-*.md`, `docs/delivery/stories/{0000,0002}-*/` | **keep** | The delivery history of the shell the app inherits — the same reason specs `0005`–`0007` stay |
| `openspec/apps/` | **replace the contents** | Both `todo.openspec.yaml` and `todoapp.openspec.yaml` go. After initialization the folder holds **exactly one** entry, and it is the new app's |
| `docs/architecture/arc42/` | **rewrite content, keep structure** | The app's architecture, not the template's |
| `docs/product/{roadmap,feature-candidates,requirements,product-brief,vision}.md` | **reset** | The app's own product docs |
| `docs/product/feature-log.md` | **reset to the legend** | The template's history is not the app's |
| `CHANGELOG.md` | **reset to header + `## [Unreleased]`** | Same reason |
| `VERSION`, `apps/mobile_app/pubspec.yaml` | **reset to `0.1.0`** | The app starts its own count |
| `docs/operations/generated-from-template.md` | **fill in, never delete** | The only remaining trace of the origin |
| `docs/template-feedback/` | **fill in, never delete** | What the template got wrong, so the next app starts better |
| `drafts/` | **delete** | Template-internal exploration |
| `drafts/init/` | **keep until processed** | The app's input material — see `drafts/init/README.md` |
| `packages/` (all of it) | **keep** | The base library set every app needs |

### The shell references the example feature

**A correct deletion list is not enough.** The classification says which paths
go; it cannot say what those paths were holding up. Five places in files
classified *keep* name the example feature, and deleting the feature without
touching them leaves a repository that does not compile:

| Where | What it does | What has to happen |
|---|---|---|
| `lib/core/database/app_database.dart` | imports `TodoItems` and declares `@DriftDatabase(tables: [TodoItems])` | point it at the new app's tables |
| `lib/core/startup/startup_providers.dart` | the `todo-list` startup task reads `todoListProvider` | replace the task with the new app's primary provider, or drop it — it is `guarded`, so nothing depends on it |
| `lib/app/router/app_router.dart` → privacy route | `onDeleteAllData` calls `ref.invalidate(todoListProvider)` | invalidate the new app's providers instead |
| `test/core/database/wipe_all_data_test.dart` | inserts through `TodoItemsCompanion` | rewrite against the new schema |
| `test/core/database/migration_test.dart` | its schema-v1 snapshot **is** the todo table | rewrite against the new schema |

The privacy one is the dangerous one. `onDeleteAllData` is the in-app
data-deletion path Google Play requires — the single thing this whole
classification is most protective about — and it has a hard dependency on the
example feature. It survives every path-based check and breaks anyway.

So `dry-run` reports **two** lists: the paths, and this reference check. The
check is mechanical — grep the shell for imports of the feature being
replaced, and require a decision for every hit:

```bash
cd apps/mobile_app && grep -rliE "todo|greet" --include="*.dart" \
  lib test integration_test \
  | grep -v "^lib/features/todos/" | grep -v "^lib/features/greeting/" \
  | grep -v "^test/features/todos/" | grep -v "\.g\.dart" \
  | grep -v "^lib/core/l10n/generated/"
```

In 3.2.1 that is twelve files, and every one of them needs a decision — the
five above, the two mixed test files, plus `app_identity.dart`, `routes.dart`,
the two web-slug tests and the screenshot flow. Nothing outside this list
mentions the example app.

Do the rewiring **before** the deletion, not after. A repository that never
stopped compiling is one where the next failure means something.

### Remove less, not more

A leftover l10n key, an unused constant or a dependency the app does not
touch yet is **harmless** — the build drops what nothing references, and a
later cleanup costs minutes.

A half-removed feature is not harmless: a route pointing at a deleted page, a
provider whose widget is gone, a call site referencing a removed function.
That is an afternoon of debugging in a codebase nobody knows yet.

So: **optimise for "nothing is broken", not for "nothing is left over".**
The same goes for libraries — the base set is what every LumbreCode app ends
up needing, and a dependency removed today is a dependency re-added in three
weeks at a different version.

### The app starts at zero

| | Template | New app |
|---|---|---|
| `VERSION` | e.g. `3.2.1` | `0.1.0` |
| `apps/mobile_app/pubspec.yaml` | `3.2.1+1` | `0.1.0+1` |
| `CHANGELOG.md` | the template's history | header + `## [Unreleased]` |
| `docs/product/feature-log.md` | the template's features | the legend, no rows |

What survives the reset is **`docs/operations/generated-from-template.md`**:
template version, template commit, generation date, app spec, and what was
replaced versus kept. Without it, six months later nobody can tell which
template improvements the app already has — and the file has a table for
recording later adoptions, too.

### Feedback flows back

`docs/template-feedback/` is filled in **while** the app is
generated and built, not afterwards. Every ambiguity, stale instruction and
wrong classification gets a row, including the ones that were worked around.

An empty feedback file after a full initialization is a suspicious result,
not a good one. The register is what turns one app's friction into the next
template version's fix.

### The shell is per-app in its *content*, not its structure

Four things to rewrite, and nothing else:

1. `docs/public-site/faq/<locale>.yaml` and
   `docs/public-site/guides/<locale>/` — the manual and FAQ for the real app.
   The bundled files under `apps/mobile_app/assets/help/` are **generated**
   from these; never edit them directly.
2. The `intro*` keys in both ARB files — what the intro says.
3. `privacyLocalBody` — what the app actually stores, if the answer is not
   "everything locally, nothing uploaded".
4. The permission list the router hands to `PrivacyPage` — empty in the
   template, so the section is omitted until the app holds a permission.

### Play Store consequences of getting this wrong

- **`lib/features/privacy/` is the in-app data-deletion path.** Google Play
  requires one for apps that collect user data, reachable from inside the
  app. Deleting the page removes it.
- The published **privacy policy** and **data-deletion** pages under
  `https://lumbrecode.de/apps/<web-slug>/` must exist before submission —
  the privacy page links to both, derived from `AppIdentity.webSlug`.
- The **Pro page shows no price and no buy action** on purpose (ADR-0015).
  A purchase surface that does not complete a purchase is a rejection
  reason. Add prices only together with a working billing adapter — see
  `docs/architecture/patterns/in-app-purchase-gateway.md`.
- The **offline licence page** on the About screen lists what the build
  actually contains, generated from `LicenseRegistry`. Keep it; a
  hand-maintained list goes stale between releases.

### The check that catches a bad initialization

After `apply`, before the quality gate:

```text
/settings  /settings/diagnostics (debug only)  /intro
/help/manual  /help/faq  /privacy  /pro  /about
```

All must still resolve, and the shell's own tests must still pass:

```bash
cd apps/mobile_app && flutter test test/features/settings test/features/onboarding test/features/help test/features/privacy test/features/monetization test/a11y
```

If a shell test was deleted rather than adapted, restore it — a deleted test
is how a deleted feature goes unnoticed.

**Three of them fail on purpose after a correct initialization.** They assert
the template's own web slug, and rewriting `AppIdentity.webSlug` is exactly
what the table tells you to do:

| Test | Assertion |
|---|---|
| `test/features/about/about_page_test.dart:64` | `https://lumbrecode.de/apps/todo-app/privacy/` |
| `test/features/about/about_page_test.dart:121,137` | `subject=[app:todo-app] Bug report` / `Feedback` |
| `test/features/splash/startup_error_page_test.dart:106` | `[app:todo-app] Startup failure: database` |

Adapt them to the new slug. **Deleting them is the wrong fix** — they are what
proves every public link and support mail is built from the app identity, and
they are the shortest path to a green gate, which is what makes deleting them
tempting. Any other red shell test is a real regression.

## What the Todo example app is

The Todo app (`apps/mobile_app/lib/features/todos/`) is a deliberate part of
the template:

- smoke test proving CI, analysis, formatting and tests work
- reference for feature-first structure, Riverpod (`riverpod_annotation`),
  Freezed models, Drift persistence, go_router and widget/unit tests
- example of generator usage (`melos run codegen`)

**It must not be deleted during general template maintenance.** It is only
replaced when the initializer runs in `apply` mode with a concrete new app
spec and `replace_todo_app: true`.

## Manual initialization checklist (without the agent)

- [ ] Record the provenance **first**: template `VERSION`,
      `git rev-parse --short HEAD`, today's date — after the reset below they
      are no longer readable from the repo
- [ ] Baseline brought to the newest release:
      `python .lumbrecode/tooling/baseline/update_baseline.py` — the
      template's `.lumbrecode/` is only as current as the template's own last
      sync, and the new app inherits that age. The script resolves the latest
      release itself, does nothing when already current, and needs
      `gh auth login`. Commit it separately from the initialization changes
- [ ] Input material collected in `drafts/init/` and listed in
      `drafts/init/processed.md`
- [ ] `openspec/apps/<app_slug>.openspec.yaml` complete
- [ ] `project.env`: `ORG="de.lumbre.code"`, `PROJECT_NAME="<app_slug>"`,
      `APP_PACKAGE="<app_slug>"`, `WEB_SLUG="<web-slug>"`,
      `WORKSPACE_FILE="<app_slug>.code-workspace"`,
      `DEVCONTAINER_NAME="<App Name>"` — all scripts, compose services and the
      initializer derive names from this single source
- [ ] External links: set `AppIdentity.webSlug` in
      `apps/mobile_app/lib/app/app_identity.dart` to the same value as
      `WEB_SLUG`. It is the **kebab-case web slug**
      (`was-there-something`), not the package slug — Android application id
      segments must not contain hyphens, so the two differ on purpose.
      Everything else follows: the public pages under
      `https://lumbrecode.de/apps/<web-slug>/` (website, support, faq,
      privacy, data-deletion, changelog, licenses) and the `[app:<web-slug>]`
      subject prefix on support mails. The mailbox addresses themselves
      (`support@`, `feedback@`, `bugs@`, `privacy@`, `security@`, `contact@`,
      `legal@lumbrecode.de`) are company-wide and stay untouched.
      **Publish the pages before the store release** — privacy policy and
      data deletion are mandatory for Google Play and the App Store
- [ ] Apply the naming: `dart tools/apply_project_naming.dart` (renames the
      `.code-workspace` file and sets the devcontainer display name from
      `project.env`; supports `--dry-run`)
- [ ] Run `scripts/bootstrap_mobile.*` (**mandatory** — native platform
      folders are not committed in the template; they are generated from
      `project.env` so they always carry the correct application id).
      In the derived app repo, commit the generated folders.
- [ ] `apps/mobile_app/pubspec.yaml`: `name`, `description`
- [ ] l10n: `splashTitle` and app strings in `lib/core/l10n/arb/`, then
      `flutter gen-l10n`
- [ ] Splash: company phase (LumbreCode,
      `lumbrecode_logo_reveal_3s_{de,en}_sequential.json`, chosen by locale)
      stays untouched; app phase shows the new name; replace
      `assets/animations/app_splash_placeholder.json` when app branding
      exists (local asset only)
- [ ] App icon: replace `apps/mobile_app/assets/images/app_icon.png` and the
      adaptive layers in `apps/mobile_app/assets/branding/` with the app's
      artwork (the template default is the LumbreCode company icon), then
      `cd apps/mobile_app && dart run flutter_launcher_icons`.
      **Must run after every bootstrap** — it writes into the generated
      `android/`/`ios/` folders and regenerates `web/icons/`.
      See `apps/mobile_app/assets/branding/README.md`
- [ ] Backend decision: keep `backend/` (Node) or `services/api/` (Dart) or
      neither. To remove ALL backend components (dirs, CI workflows, compose
      services, workspace tasks) in one step run
      `./scripts/remove_backend.sh` / `.\scripts\remove_backend.ps1`
      (supports `--dry-run`), then clean the prose docs it lists
- [ ] Replace the Todo feature with your app's first feature (keep the
      structure and test style as reference before deleting). **Only the
      example feature** — see "What is kept, adapted and replaced" above;
      the settings hub, intro, help, privacy, Pro and about pages stay
- [ ] **Rewire the shell before deleting the example** — `app_database.dart`,
      `startup_providers.dart`, the privacy route's `onDeleteAllData` and the
      two database tests all name the todo feature. See "The shell references
      the example feature"
- [ ] Move the settings and about entry points from the greeting page's app
      bar onto the new app's main screen, or the shell becomes unreachable
- [ ] Rewrite the shell's per-app content: `assets/help/*.md`, the `intro*`
      l10n keys, `privacyLocalBody`, and the `PrivacyPage` permission list
- [ ] Verify the shell survived: `/settings`, `/intro`, `/help/manual`,
      `/help/faq`, `/privacy`, `/pro`, `/about` still resolve and their
      tests still pass — except the three web-slug assertions, which are
      **adapted, never deleted**
- [ ] `openspec/apps/` holds exactly one entry, and it is this app's
- [ ] Documentation: delete the example-app specs (`0001`–`0004`),
      `docs/ideas/`, the todo plan `0001` and its review; **keep** the shell
      specs (`0005`–`0007`), the shell's plans and stories (`0000`, `0002`),
      the contracts, the patterns, `known-issues.md` and `docs/operations/`;
      rewrite the arc42 content for this app
- [ ] `drafts/` emptied — **except `drafts/init/`**
- [ ] `melos run codegen` && `melos run ci`
- [ ] Update `README.md`
- [ ] Reset the history: `VERSION` and `apps/mobile_app/pubspec.yaml` to
      `0.1.0` / `0.1.0+1`, `CHANGELOG.md` to header + `## [Unreleased]`,
      `docs/product/feature-log.md` to its legend
- [ ] Fill in `docs/operations/generated-from-template.md` — template
      version, template commit, date, what was replaced, what was kept
- [ ] Fill in `docs/template-feedback/` — everything about the
      template that got in the way, including what you worked around
- [ ] Retire `drafts/init/` once every row in its `processed.md` says `done`
      or `dropped`

## Known template state

- Native platform folders (`android/`, `ios/`, `linux/`, ...) are **not
  committed** in the template. Running the bootstrap scripts after setting
  `project.env` generates them with `de.lumbre.code.<app_slug>` — there is
  no stale-id trap. Derived app repos commit their generated folders.
