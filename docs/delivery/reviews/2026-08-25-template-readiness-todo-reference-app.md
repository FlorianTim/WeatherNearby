# Current-state audit: what template 3.0.0 offers the To-do reference app

- **Date:** 2026-08-25
- **Scope:** template version 3.0.0, branch `feat/adopt-wts-1.3.1-learnings`
- **Purpose:** deliverable A of the 3.1.0 planning pass. Establishes what the
  reference app must reuse, what is thinner than the draft assumes, and what
  the draft got wrong.
- **Method:** every claim below was checked against the code, not against
  `drafts/notes/3.1.0/lumbrecode_todo_app_notes.md`.

---

## 1. Verdict in one table

| Draft 14.1 claim | Verified state | Consequence for 3.1.0 |
|---|---|---|
| Just-in-time permission flow with rationale sheet — `core/permissions/` | exists, but **interface only** | `ensurePermission` + `PermissionGateway` + rationale/blocked sheets are real. There is **no concrete gateway and no permission plugin** anywhere in the tree — the only implementation is `test/support/fake_permission_gateway.dart`. Slice 6 must write the first real gateway and adopt a plugin. |
| Startup coordinator and startup tasks — `core/startup/` | exists and is used | `startupTasks` currently registers `database` (blocking) and `todo-list` (guarded). The guarded entry points at the demo and must move with slice 13. |
| Settings register (`SettingDef`) — `core/settings/` | exists | Two settings today (`app.locale`, `app.themeMode`). The app adds several; the register scales without change. |
| Two-phase splash — `features/splash/` | exists | Company phase stays. App phase placeholder gets the To-do app name. |
| Branding, flavor, app links, support mail — `packages/app_core` | exists | `AppBranding`, `AppConfig`, `AppFlavor`, `AppLinks`. Nothing to add. |
| Calendar-correct date validation — `packages/app_core/date_validation.dart` | exists | `DateValidation` on `time_machine2` 0.14. Good enough for calendar validity; it does **not** give epoch-day storage or a recurrence engine. |
| Theme and spacing tokens — `packages/design_system` | exists, but **very thin** | The whole package is `AppTheme`, `AppSpacing`, `AppSection`. There is no text style scale, no list-row widget, no snackbar helper, no Markdown anything. The Markdown editor lands in an almost empty package. |

---

## 2. What exists and is genuinely reusable

### 2.1 Database hardening — better than the draft assumes

`apps/mobile_app/lib/core/database/app_database.dart` already carries most of
what draft 14.1 lists as "must be added":

- `PRAGMA foreign_keys = ON` in `beforeOpen` — present.
- Downgrade guard (`versionBefore > versionNow` throws a readable `StateError`)
  — present, and stricter than the draft asks for.
- `addColumnIfMissing(...)` — idempotent additive migration helper, present.
- `wipeAllData()` in a transaction, deleting in reverse declaration order.
- `DriftWebOptions` wired for the web target.
- A migration fixture test exists: `test/core/database/migration_test.dart`.

**What is actually missing** is not the conventions but their *exercise*: the
schema is one flat table (`TodoItems`: id, title, description, status,
createdAt, completedAt), `schemaVersion` is 1, and `onUpgrade` is an empty
commented scaffold. Nothing in the template proves a foreign key, a
multi-table transaction, a `TypeConverter`, or a chained N-2 to N migration.
That is exactly the gap 3.1.0 is meant to close.

### 2.2 Platform seams — the pattern is right, the coverage is small

`core/platform/platform_seams.dart` defines three injectable seams as
`@Riverpod(keepAlive: true)` typedef providers: `LaunchUrl`, `ShareText`,
`CopyToClipboard`, plus `packageInfo` and `deviceInfo`.

Two gaps that matter:

1. **`urlLauncher` has no scheme allowlist.** It calls
   `url_launcher.launchUrl(uri, mode: externalApplication)` for any URI it is
   handed. The interop guide 2.7 and 10.7 require that only `https:` and
   `http:` ever launch. Today that rule would have to be enforced at every
   call site, which is how it gets forgotten.
2. **`ShareText` shares text only.** Sharing a *typed document file* — which
   is what the contract requires (guide 6.1: "a file, not `EXTRA_TEXT`") —
   has no seam.

### 2.3 Permissions — the hard part is done, the easy part is missing

The order that apps get wrong (`status` then the permanently-denied branch,
then a rationale, then `request`) is implemented once, in `ensurePermission`,
with the four-state `PermissionState` enum kept deliberately distinct. That is
the valuable half and it is reusable as-is for `POST_NOTIFICATIONS`.

The missing half is mundane: no `permission_handler` (or equivalent) is in any
pubspec, and no class in `lib/` implements `PermissionGateway`.
`docs/architecture/patterns/permissions.md` sketches the implementation and
names `permission_handler` as the intended package, but it is a pattern doc,
not code.

### 2.4 Accessibility — contract plus a working example

`docs/architecture/contracts/07-accessibility.md` has 11 verifiable rules and
records the template's own status honestly (rules 7 and 11 are partial). Tests
live in `test/a11y/accessibility_test.dart` against the settings page. Rule 10
("every swipe gesture has an alternative") is currently satisfied trivially,
because nothing in the template swipes. The To-do app introduces swipe
actions, so rule 10 becomes a real obligation for the first time.

### 2.5 Localization

`flutter gen-l10n` with `app_de.arb` as the **template** ARB and `app_en.arb`
as the translation. Both files carry the same 64 keys — no drift. 13 of those
keys belong to the demo (`todosTitle`, `todoCreate`, `todoStatusPending`, ...)
and are slice-13 removals.

Note for widget tests: KI-005 records that a test without an explicit locale
resolves to `en` while the template ARB is `app_de.arb`; the harness helper
`wrapWithL10n` defaults to `de`.

---

## 3. What is missing outright

| Need | Status today | Where it must land |
|---|---|---|
| Markdown rendering | nothing | `packages/design_system` |
| Markdown editor with toolbar and action row | nothing | `packages/design_system` |
| Snackbar / undo helper | nothing | `packages/design_system` |
| Typed-document share seam | text-only seam | `core/platform/` |
| URL-launcher scheme allowlist | unrestricted seam | `core/platform/` |
| Notification seam + scheduling | nothing | `core/notifications/` |
| Concrete `PermissionGateway` + plugin | interface + fake only | `core/permissions/` |
| Epoch-day / minutes-of-day converters | rules documented in the DB contract (rule 6, status partial) | `core/domain/time/` |
| RFC 5545 recurrence subset parser | nothing | `packages/task_interchange` |
| JSCalendar models + codec | nothing | `packages/task_interchange` (new) |
| Golden fixtures from `lumbrecode-engineering` | **nothing — see 4.2** | `packages/task_interchange/test/fixtures/` |
| Android intent filter for receiving | nothing, and see 4.3 | bootstrap script |
| Cache-directory access (`path_provider`) | not a dependency | app |
| Trash / archive / backup modules | patterns documented, no code | app / later |

---

## 4. Where the draft is wrong against the actual code

These are the corrections the finishing instructions ask for. Each was
verified.

### 4.1 KI-001 — the template *does* have the analyzer/riverpod lock

> Draft 13.4: "The template has **no** analyzer/riverpod lock of the kind
> WasThereSomething suffers (KI-001), so there is more freedom here."

**Wrong.** `docs/known-issues.md` KI-001 is this template's own entry, status
**"blocking (verified 2026-07-23, still applies to this template)"**. The
locked tree confirms it: `analyzer 8.4.0`, `custom_lint 0.8.1`,
`drift 2.31.0`, `drift_dev 2.31.0`, `flutter_riverpod 3.0.3`,
`riverpod_generator 3.0.3`. `sqlite3_flutter_libs 0.5.42` is kept although it
is end-of-life, as documented accepted debt.

Consequence for 3.1.0: the new dependencies must be checked against this tree
*before* adoption (library-evaluation contract rule 10). The good news is that
every package the app needs — `flutter_local_notifications`, `timezone`,
`path_provider`, `mime`, `flutter_markdown_plus` — is a **runtime**
dependency with no analyzer constraint, so none of them should move the lock.
`receive_sharing_intent` is the only one worth resolving explicitly before
committing to it, and ADR-0013 recommends against it anyway.

Do **not** treat this as "more freedom". Treat it as: resolve first, adopt
second.

### 4.2 The fixtures do not arrive automatically here

> Interop guide 15.3: "They arrive automatically at `.lumbrecode/schemas/`
> through the baseline sync (`profiles/common.json`)."

There is **no `.lumbrecode/` directory in this repository** and no baseline
sync wired into it. The 24 JSCalendar fixtures and the 21 exchange fixtures
exist only in the sibling repo at
`lumbrecode-engineering/schemas/.../v1/examples/`.

Consequence: slice 1 has to decide how fixtures reach
`packages/task_interchange/test/fixtures/`. This is the second instance of
open question Q-05 (distribution), and it blocks the contract tests, so it
cannot be left open. Recommendation in ADR-0014: vendor a copy with a recorded
source commit and a checksum test, until the baseline sync exists.

### 4.3 `android/` is not committed — the manifest cannot simply be edited

The draft and the interop guide 6.2 both present the intent filter as an edit
to `apps/mobile_app/android/app/src/main/AndroidManifest.xml`. That file
**does not exist in the repository**. `apps/mobile_app/` has no `android/`
directory at all; it is produced by `scripts/bootstrap_android.sh`, and the
only Android-specific artefacts under version control are
`scripts/bootstrap/android-res/` plus the manifest patcher
`_apply_backup_policy` in `scripts/lib/apply_android_branding.sh` (and its
PowerShell twin `scripts/lib/Apply-AndroidBranding.ps1`).

Consequence: registering the receive filter is a **build-tooling change**, not
a manifest edit, and it needs both the bash and the PowerShell path. This is
the single most likely thing for an implementation agent to get wrong. It is
why ADR-0013 exists.

### 4.4 `generateId()` is a documented template decision, not a WTS workaround

> Draft 13.2: "**Use this [`uuid`]**, not WTS's hand-rolled `generateId()` —
> that exists only because of WTS's dependency lock."

Partly wrong. This template has its own `core/utils/id_generator.dart` whose
doc comment explicitly cites **rule 9 of the library-evaluation contract**
("no large dependency for a trivial problem", with UUID generation as the
named example) as the reason it exists. It is a template decision, not an
inherited workaround.

That does not make the draft's conclusion wrong — JSCalendar `uid` must be an
RFC 4122 v4 UUID in canonical lowercase, and the current `generateId()`
produces a 32-char hex string that is **not** a UUID. The resolution is narrow
and is recorded in ADR-0014: add a small `Uuid4` helper to
`packages/app_core` implemented on `Random.secure()` with the version and
variant bits set, keep `generateId()` for local row ids, and do not add the
`uuid` package. Rule 9 is satisfied and the contract is met.

### 4.5 `share_plus` 12.x — verified signature

The draft is right that the API changed and right to demand verification. The
resolved version is **12.0.2**, and the seam in `platform_seams.dart` already
uses the instance API. Verified against the resolved package
(`share_plus_platform_interface 6.1.0`):

```dart
// text (already in the template)
await SharePlus.instance.share(ShareParams(text: text));

// typed document file (what slice 9 needs)
await SharePlus.instance.share(
  ShareParams(files: [XFile(path, mimeType: mediaType)]),
);
```

`ShareParams` takes `List<XFile>? files` and `List<String>? fileNameOverrides`.
`XFile` is re-exported from `package:share_plus/share_plus.dart`, so **no
separate `cross_file` dependency is needed**. The guide's 10.x snippet
(`Share.shareXFiles(...)`) does not compile here.

### 4.6 `timezone` is not yet in the tree

The draft lists `timezone` as "to add" without noting the risk. KI-009(a) is
the recorded worked example of two packages becoming mutually unresolvable
through exactly this package. `flutter_local_notifications` pulls `timezone`
transitively; nothing else in the current tree depends on it, so the conflict
surface today is empty. Record the constraint when it is added so the next
package that wants `timezone` finds the note.

### 4.7 `time_machine2` is already a dependency — of `app_core`, not the app

Draft 13.2 lists `time_machine2` under "to add". It is already there, at
0.14.0, as a dependency of `packages/app_core`. `apps/mobile_app` gets it
transitively through `app_core`. Nothing to add; something to reuse.

### 4.8 Contract tension: the exchange profile defines `upsert`, this app cannot honour it

Not a draft error — a genuine conflict between two binding documents, found
while checking the fixtures.

- `JSCALENDAR_TASK_INTEROP.md` 10.2 is absolute: a familiar `uid` never
  triggers a merge, a link or a sync.
- `LUMBRECODE_EXCHANGE.md` rule 8 defines
  `de.lumbrecode.exchange.jscalendar.upsert.v1`, whose stated meaning is "the
  receiver may create **or update** the matched object", with a matching table
  keyed on `(sourceappid, data.uid)`.
- Golden fixture `20-task-in-envelope.json` carries `upsert.v1`. Fixture
  `21-task-group-in-envelope.json` carries `import.v1`.

So an app that rejected `upsert.v1` would fail on a golden fixture, and an app
that implemented it as an update would break the interop guide's most emphatic
rule.

Resolution taken in spec 0004 (INT-141): accept **both** types, execute
**both** as import-a-new-copy, and emit a counted warning when the type was
`upsert.v1` saying the sender offered an update and a copy was created
instead. `upsert` is a *permission* the sender grants ("you may update"), not
an instruction, and the receiver is free not to have a matching model. This is
carried to the contract owner as spec 0004 Q-04 so the guide can say so
explicitly.

---

## 5. Version deltas against WasThereSomething — confirmed

| Package | This template (locked) | WTS 1.5 | Note |
|---|---|---|---|
| `flutter_riverpod` | 3.0.3 | 3.1.0 | same line |
| `riverpod_annotation` | 3.0.3 | ^4.0.0 | **different major** — generator API differs |
| `go_router` | 14.8.1 | ^17.3.0 | **different major** — routing API differs |
| `drift` / `drift_dev` | 2.31.0 | 2.31.0 | same |
| `freezed` | 3.2.3 | 3.x | same |
| `json_serializable` | 6.11.2 | 6.x | same |
| `share_plus` | 12.0.2 | 10.1.4 | **two majors apart** — see 4.5 |
| `url_launcher` | 6.3.2 | 6.3.2 | same |
| `time_machine2` | 0.14.0 (via `app_core`) | 0.14.0 | same |
| `analyzer` | 8.4.0 | — | the KI-001 ceiling |

Rule for every slice: copy WasThereSomething's *reasoning*, never its
*snippets*, without compiling them here first.

---

## 6. Demo footprint — what slice 13 has to remove

| Kind | Location | Count |
|---|---|---|
| Feature sources | `lib/features/todos/**` | 12 hand-written `.dart` (+ generated) |
| Tests | `test/features/todos/**` | 4 files |
| Table | `TodoItems` in `lib/features/todos/data/tables/todo_table.dart`, registered in `@DriftDatabase` | 1 |
| Routes | `AppRoutes.todos`, `AppRoutes.todoDetail`, their `GoRoute`s | 2 + 2 |
| Startup task | `todo-list` (guarded) in `core/startup/startup_providers.dart` | 1 |
| l10n keys | `todosTitle`, `todoCreate`, `todoCreateTitle`, `todoDelete`, `todoDescriptionLabel`, `todoEmpty`, `todoErrorLoading`, `todoRequired`, `todoRetry`, `todoStatusCompleted`, `todoStatusInProgress`, `todoStatusPending`, `todoTitleLabel` | 13 x 2 ARB |
| Integration tests | `integration_test/app_flow_test.dart`, `app_screenshots_test.dart` reference the demo | 2 |
| Docs | `README.md`, `AGENTS.md`, `openspec/README.md`, `openspec/apps/todoapp.openspec.yaml`, `.github/copilot-instructions.md`, `.github/agents/template-initializer.agent.md`, `docs/operations/template-initialization.md` | 7 |

Note the enum trap the draft flags and the code confirms: the demo uses
`TodoStatus {pending, inProgress, completed}`. `pending` is not
`needs-action`, and `failed`/`cancelled` are missing. The new domain does not
reuse this enum, and the migration does not carry these rows over — see spec
0001 `data-contract.md`, section "Migration from the demo schema".

---

## 7. Summary of what this audit changes in the plan

1. Slice 0 grows a **concrete permission gateway** and its plugin decision,
   which the draft assumed was already there.
2. Slice 0 grows a **URL scheme allowlist** in the launcher seam, because the
   seam exists but is unrestricted.
3. Slice 1 must **resolve fixture distribution** (4.2) — it cannot be
   deferred, because CT-1 to CT-15 depend on it.
4. Slice 8 is a **build-tooling change plus app code** (4.3), not a manifest
   edit, and needs a bash and a PowerShell path.
5. No `uuid` package (4.4); a `Uuid4` helper in `app_core` instead.
6. Every new dependency is resolved against the KI-001 tree before adoption
   (4.1), and `timezone` gets a recorded constraint note (4.6).
7. Spec 0004 has to state a position on `upsert.v1` (4.8) rather than inherit
   a contradiction.
