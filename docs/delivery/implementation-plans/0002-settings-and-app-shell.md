# Implementation Plan: Settings hub and app shell

## Metadata

- **Status:** approved
- **Feature specs:** `docs/product/specs/0005-settings-hub-and-in-app-help/`,
  `0006-onboarding-and-app-intro/`, `0007-in-app-purchase-placeholder/`
- **Target release:** 3.2.1 (`now`)
- **Created:** 2026-08-26
- **Decisions:** ADR-0015 (purchase seam without the plugin dependency)
- **Reference behaviour:** *WasThereSomething* `release/1.3.1` — its settings
  hub (`features/more/`), onboarding, privacy page and Pro page
- **Predecessor:** `docs/ideas/wts-1.3.1-adoption-delta.md` (waves 1–4,
  shipped as template 3.0.0)

## Scope

The **app shell** — everything a LumbreCode app has around its features:

1. A settings **hub** instead of a settings *page*: language, appearance,
   help, privacy and data, Pro, support, and a debug-only diagnostics entry.
2. **In-app help documents** — a bundled, localized manual and FAQ, rendered
   from Markdown assets.
3. An **in-app privacy page** — what the app stores, which permissions it
   holds, the published legal documents, and the two destructive actions.
4. A **first-start intro** (onboarding) that can be replayed from settings.
5. An **in-app-purchase placeholder** — entitlement cache, purchase gateway
   seam, Pro page — **without** adding a billing dependency.

Everything general enough for a derived app goes into `packages/` in the
slice that introduces it, never "later" (ADR-0011, decision 4).

## Non-scope

- Real purchases: products, prices, buy and restore against a live store.
  ADR-0015 explains why the seam ships without the plugin.
- A backup/export feature. Named as a 3.2+ candidate in
  `0001-todo-reference-app.md`; it needs its own spec because the file
  format is a compatibility promise.
- Per-feature settings of the reference app (reminder lead time, completed
  visibility). Those belong to specs 0001–0003 and land with them.
- A concrete `PermissionGateway` implementation. The privacy page renders
  the permission overview it is given; the template hands it an empty list
  until spec 0003 brings the first real permission.
- Rewriting the About page. It already covers the external links and the
  support mailboxes; the hub links to it instead of duplicating it.

## Relevant docs

- `docs/architecture/contracts/` — 01 startup, 03 localization,
  04 permissions, 05 external data ownership, 07 accessibility
- `docs/known-issues.md` — KI-001, KI-003
- ADR-0011 (reference app), ADR-0015 (purchase seam)
- `docs/architecture/patterns/platform-gateways.md` — the seam pattern the
  purchase gateway follows

---

## Proposed technical approach

### The rule that shapes every slice

**A template ships the shape, not the content.** A manual, a privacy text and
a product catalogue are app-specific; the *page that renders them*, the
*asset convention* and the *gateway they talk to* are not. So every slice
below ships a tested, working surface plus one honest example, and never a
dependency a derived app would have to delete.

That is the same decision the 3.0.0 adoption took for capability modules:
what needs no new dependency becomes template code, what drags in a plugin,
a manifest entry or a store declaration becomes a documented recipe.

### The startup flow changes

Today the settings page **is** the first-run screen — the splash routes into
it, and it carries a "Continue" button. That conflates two things: a wizard
step, and a place you come back to.

```text
before:  splash --> settings --[Continue]--> greeting
after:   splash --> intro (first start only) --> greeting --> settings hub
              \--> greeting (every later start)
```

The language and appearance choice is not lost: it becomes a step **inside**
the intro, using the same option tiles as the hub. First start still asks;
every later start goes straight to the app.

### Architecture target

```text
packages/design_system/lib/src/widgets/
  app_option_tile.dart      AppOptionTile           - the radio-style card
  app_settings_tiles.dart   AppSettingsSection/Tile - hub building blocks

apps/mobile_app/lib/
  core/settings/            + onboardingCompleted, entitlement, checkedAt
                            + resetAllSettings()
  features/
    settings/               the hub + the debug-only diagnostics page
    help/                   HelpDocumentPage, assets/help/<doc>_<lang>.md
    privacy/                PrivacyPage - storage, permissions, legal, danger
    onboarding/             the intro pager + its persisted flag
    monetization/           gateway seam, entitlement cache, Pro page
```

---

## The slices

| # | Slice | Spec | Ships |
|---|-------|------|-------|
| 1 | Hub building blocks | 0005 | `AppOptionTile`, `AppSettingsSection`, `AppSettingsTile` in `design_system` |
| 2 | Settings hub | 0005 | The restructured page, its sections, routes, debug diagnostics |
| 3 | In-app help | 0005 | `HelpDocumentPage`, four Markdown assets, locale fallback |
| 4 | Privacy and data | 0005 | `PrivacyPage`, permission overview seam, both destructive actions |
| 5 | App intro | 0006 | `onboardingCompleted` setting, the pager, routing, replay entry |
| 6 | Purchase placeholder | 0007 | Gateway seam, entitlement cache, Pro page, the recipe |
| 7 | Release | — | Version 3.2.1, changelog, README, roadmap, contracts |

### Why this order

Slices 1–2 come first because every later slice needs a row in the hub to be
reachable — building the hub last would mean six screens nobody can open.
Slice 5 changes routing and therefore depends on the hub existing (the
replay entry lives in it). Slice 6 is the last feature slice because it is
the only one a derived app may legitimately delete whole.

### Dependency graph

```text
1 --> 2 --+--> 3
          +--> 4
          +--> 5
          +--> 6 --> 7
```

---

## Data / Model changes

Three new entries in the `AppSettings` register (`core/settings/`), all
through the existing `SettingDef` mechanism — no new storage:

| Key | Type | Default | Meaning |
|---|---|---|---|
| `app.onboardingCompleted` | `bool` | `false` | Intro was finished or skipped |
| `billing.entitlement` | `Entitlement` | `free` | Locally cached entitlement |
| `billing.checkedAt` | `DateTime?` | `null` | Last store verification (UTC, ISO-8601) |

No database schema change. `wipeAllData()` is untouched: it clears content,
never settings — the two destructive actions stay separate on purpose.

## API changes

None. No endpoint, no backend contract.

## UI changes

| Screen | Route | State |
|---|---|---|
| Settings hub | `/settings` | rebuilt |
| Settings diagnostics | `/settings/diagnostics` | new, debug builds only |
| Manual | `/help/manual` | new |
| FAQ | `/help/faq` | new |
| Privacy and data | `/privacy` | new |
| App intro | `/intro` | new |
| Pro | `/pro` | new |

## Tests and validation

- **Unit:** setting round-trips and degradation for the three new keys;
  `resetAllSettings()`; entitlement decode of an unknown stored value;
  `FeatureGates` fail-open; the help asset path and fallback rule.
- **Widget:** every new page; the hub's debug section is absent in release
  mode; both confirmation dialogs; the intro's skip and finish paths; the
  Pro page in all three store states.
- **Routing:** first start reaches the intro, a completed flag skips it, the
  replay entry reopens it.
- **Accessibility:** `test/a11y/accessibility_test.dart` is extended to the
  rebuilt hub — touch targets, text scaling, selection state that does not
  depend on colour alone.
- **Commands:** `scripts/dev/quality_gate.sh`, `melos run codegen`.

## Risks

| Risk | Mitigation |
|---|---|
| The startup-flow change breaks derived apps that route to `/settings` after the splash | The route keeps its path and still works; only the *default destination* moves. Called out in the changelog as a behaviour change. |
| Help assets drift from the app | The manual is deliberately about the *template*, not about a feature — a derived app replaces the file, and a missing asset fails visibly (`helpLoadError`) instead of silently. |
| The Pro page suggests purchases that do not exist | The page states that all features are currently free and shows store availability only. No price, no buy button (ADR-0015). |
| A new setting key collides with an existing one | The uniqueness test over `AppSettings.all` covers the new keys automatically. |

## Rollout / Migration notes

For an app already derived from template 3.0.0:

1. `app.onboardingCompleted` is absent, so an existing installation sees the
   intro once. That is intended — it is new content, not a regression.
2. Anything that navigated to `AppRoutes.settings` expecting a "Continue"
   button must drop that expectation; `onContinue` is gone.
3. `_OptionTile` moved out of `settings_page.dart` into `design_system` as
   `AppOptionTile`. A private copy in a derived app keeps working, but
   should be replaced.

## Definition of done, per slice

- Tests for the slice pass, and the whole suite still passes.
- `melos run analyze` clean, `format:check` clean, codegen idempotent.
- Every user-visible string exists in **both** ARB files.
- The slice's story is checked off and the changelog wave entry written.

## Story breakdown

| # | Story | Status |
|---|-------|--------|
| 1 | `story-001-settings-building-blocks.md` | ready |
| 2 | `story-002-settings-hub.md` | ready |
| 3 | `story-003-in-app-help-documents.md` | ready |
| 4 | `story-004-privacy-and-data-page.md` | ready |
| 5 | `story-005-app-intro.md` | ready |
| 6 | `story-006-purchase-placeholder.md` | ready |
| 7 | `story-007-release-3.2.1.md` | ready |
