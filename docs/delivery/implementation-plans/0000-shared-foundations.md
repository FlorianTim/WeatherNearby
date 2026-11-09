# Implementation Plan: Shared foundations (slice 0)

## Metadata

- **Status:** draft
- **Feature spec:** none — this plan serves specs 0001–0004 rather than one of
  them. It is the **template** half of 3.1.0.
- **Target release:** 3.1.0 (`now`)
- **Created:** 2026-08-25
- **Decisions:** ADR-0011 (reference app), ADR-0012 (notification boundary),
  ADR-0014 (interchange package and the `Uuid4` helper)
- **Audit:** `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md`

## Scope

Deliverable D of the 3.1.0 planning pass: **for each shared component the
reference app forces into existence — its target location, its public API
sketch, and the slice that extracts it.**

ADR-0011 decision 4 is the rule this plan implements:

> Anything the app needs that is not specifically about to-do lists lands in
> `packages/` or `core/`, **in the slice that introduces it**.

The test for membership is simple: *would a vacation planner want this too?*
If yes, it is template surface. If it only makes sense for tasks, it stays in
`features/tasks/`.

### The warning this plan exists to prevent

The temptation will be to leave the Markdown editor, the seams and the
converters inside `features/tasks/` because that is where they are first
needed, and to extract them later.

**Later does not happen.** By the time the app works, the component has three
call sites that assume a task, its tests live in the feature's test folder,
and extraction is a refactor nobody has budget for. Every row in the table
below names the slice that owns the extraction, and "later" is not one of the
values.

## Non-scope

- Anything task-specific. The task model, the views, the reminders and the
  interop feature are specs 0001–0004.
- `packages/task_interchange` itself. It is template surface too, but it is
  large enough to be its own slice (slice 1) and its own ADR (ADR-0014). This
  plan covers only the `Uuid4` helper it depends on.
- The candidates in draft §14.1's "general, but not forced by this app"
  table — the in-app manual, feedback-by-mail, backup/restore, privacy field
  classes, archive-before-delete. They are real and they are 3.2+, because
  nothing in 3.1.0 forces them and speculative extraction is how packages
  acquire unused surface.

## Relevant docs

- ADR-0011 (why the reference app exists), ADR-0012 (notification seam),
  ADR-0014 (`Uuid4` versus the `uuid` package)
- `docs/architecture/contracts/06-library-evaluation.md` — every dependency
  below is justified against it
- `docs/architecture/contracts/02-database.md` rule 6 — the converters close
  its "partial" status
- `docs/architecture/patterns/platform-gateways.md` — the seam pattern
- `docs/known-issues.md` KI-001, KI-004, KI-005, KI-009

## The extraction table

Every row: what, where, which slice, and why it is general.

| # | Component | Target | Extracted in | Why it is general |
|---|---|---|---|---|
| 1 | Epoch-day + minute-of-day converters | `apps/mobile_app/lib/core/domain/time/` | **0** | Any app with dates needs them. Closes database-contract rule 6, currently marked partial "until the first date-heavy app". |
| 2 | `Uuid4` helper | `packages/app_core` | **0** | Several standards want RFC 4122. Standardize once (ADR-0014). |
| 3 | URL-launcher seam **with a scheme allowlist** | `core/platform/platform_seams.dart` | **0** | Security-relevant and identical in every app. The seam exists; the allowlist does not. |
| 4 | Typed-document share seam | `core/platform/platform_seams.dart` | **0** | Every app shares something. No widget test may open a real share sheet. |
| 5 | Snackbar / undo helper | `packages/design_system` | **0** | "Undo for risky quick actions" is a cross-app product rule, not a task feature. |
| 6 | Markdown **renderer** | `packages/design_system` | **0** | Same renderer, same defaults, everywhere. |
| 7 | Markdown **editor** with toolbar and action row | `packages/design_system` | **0** | Named explicitly by the product owner. Every app with a free-text field should feel identical. |
| 8 | Drift hardening conventions | `core/database/` + contract text | **0** (docs) / **2** (exercise) | Today's demo has one flat table and proves none of it. |
| 9 | Concrete `PermissionGateway` | `core/permissions/` | **6** | The template has the flow and no implementation. The first real one is the notification permission. |
| 10 | `NotificationGateway` seam | `core/notifications/` | **6** | Local-only scheduling, injectable for tests (ADR-0012). |
| 11 | Pending-action queue | `core/notifications/` | **6** | Any app with a notification action faces the identical isolate boundary. |
| 12 | `packages/task_interchange` | new package | **1** | Generic JSCalendar model and codec; no Flutter, no Drift (ADR-0014). |

Rows 1–8 are slice 0. Rows 9–11 belong to slice 6 because they cannot be
designed honestly without the feature that uses them — but they are listed
here so their **target location** is decided now, not when the pressure is on.

---

## Component designs

### 1. Epoch-day and minute-of-day converters

**Target:** `apps/mobile_app/lib/core/domain/time/`

Why here and not in a package: they are needed by exactly one consumer today,
and promoting them is a one-file move when a second app wants them. Recorded
as spec 0001 Q-1g.

```dart
/// A calendar day as an epoch-day integer. Not a moment.
extension type const EpochDay(int value) {
  static EpochDay fromLocalDate(LocalDate d);
  LocalDate toLocalDate();
}

/// Minutes since midnight, 0..1439. Not a duration, not a moment.
extension type const MinuteOfDay(int value) { … }

class EpochDayConverter    extends TypeConverter<EpochDay, int> { … }
class MinuteOfDayConverter extends TypeConverter<MinuteOfDay, int> { … }
```

Rules the implementation must carry, each from a recorded trap:

- Converters are declared on the **storage** type
  (`integer().map(const EpochDayConverter())`), never on `dateTime()` —
  KI-004.
- The converter must be imported into the **database library file**, not only
  into the table file, or codegen fails with `Couldn't find constructor` —
  KI-004.
- Calendar validity goes through `DateValidation` in `packages/app_core`
  (already present, on `time_machine2` 0.14), not a hand-written month-length
  switch.
- All-day intervals are **half-open**: the end is the first moment not
  included — database contract rule 6.

**Tests:** round trip over a year including both DST transitions; rejection of
impossible dates; the half-open interval boundary; a Drift round trip through
an actual table.

### 2. `Uuid4`

**Target:** `packages/app_core`

```dart
abstract final class Uuid4 {
  /// RFC 4122 v4, canonical lowercase, from Random.secure().
  static String generate();
  static bool isCanonical(String value);
}
```

Roughly fifteen lines: sixteen secure-random bytes, version nibble to `4`,
variant bits to `10`, canonical formatting.

**`generateId()` stays as it is** for local row ids. The two are deliberately
separate: a row id is a database detail with no format contract; a `uid` is an
identity that survives leaving the app and must satisfy RFC 4122. Adding the
`uuid` package for fifteen lines would violate library-evaluation rule 9 —
whose named example is, verbatim, UUID generation (ADR-0014, and the audit
§4.4 which corrects the draft on this point).

**Tests:** property test over 100 000 draws — canonical form, version nibble,
variant bits, distinctness.

### 3. URL-launcher seam with a scheme allowlist

**Target:** `core/platform/platform_seams.dart` (the seam exists; the
allowlist does not)

The current `urlLauncher` provider hands any `Uri` to
`url_launcher.launchUrl`. The interop contract requires that only `https:`
and `http:` ever launch, and that every other scheme is displayed but not
opened. Enforcing that at each call site is how it gets forgotten.

> **Corrected during implementation.** A single `http`/`https` allowlist
> would have **broken the template's existing feedback-mail path**: `mailto:`
> URIs built by `FeedbackMailBuilder` are launched through this same seam
> from the about page and the startup-error page. The contract's rule is
> about links from an **untrusted document**, not about every URI the app
> itself constructs — so the allowlist became a policy the caller names.

```dart
enum LaunchOutcome { launched, schemeNotAllowed, failed }

enum UrlPolicy {
  /// The DEFAULT, so forgetting is safe. Anything the app did not author.
  webOnly({'http', 'https'}),
  /// Only for URIs the app constructed itself, e.g. a prefilled support mail.
  appAuthored({'http', 'https', 'mailto'});
}

typedef LaunchUrl =
    Future<LaunchOutcome> Function(Uri uri, {UrlPolicy policy});
```

The provider checks the scheme **before** calling the plugin and returns
`schemeNotAllowed` without launching. Returning an outcome rather than a
`bool` is what lets the UI say *why* nothing happened.

`webOnly` is the default precisely because the dangerous case is the one a
caller forgets to think about. Widening a set is a new policy value with its
own justification, never an edit to an existing one — a test asserts the two
sets have not grown.

**Breaking change, deliberately:** the return type changes from
`Future<bool>`. Two call sites exist today; changing the type now is cheaper
than adding a second, safe variant and hoping people use it.

**Tests:** `https` and `http` launch; `mailto:`, `tel:`, `file:`,
`javascript:`, `content:`, `intent:`, `data:` and a scheme-less URI are
refused under `webOnly`, each returning `schemeNotAllowed`. The refusal test
runs against the **real** provider without a plugin binding — if the check
ever moves to after the plugin call, the test fails with "Binding has not yet
been initialized" instead of passing quietly.

### 4. Typed-document share seam

**Target:** `core/platform/platform_seams.dart`

```dart
final class SharePayload {
  final String fileName;    // *.jscalendar.json
  final String mediaType;   // application/jscalendar+json;type=task|group
  final String bytesUtf8;
}

typedef ShareDocument = Future<void> Function(SharePayload payload);
```

The implementation writes to the app-private cache and calls — **verified
against the resolved `share_plus 12.0.2` / `share_plus_platform_interface
6.1.0`**:

```dart
await SharePlus.instance.share(
  ShareParams(files: [XFile(path, mimeType: payload.mediaType)]),
);
```

`XFile` is re-exported from `package:share_plus/share_plus.dart`, so **no
`cross_file` dependency is needed**. The interop guide's 10.x
`Share.shareXFiles(...)` snippet does not compile here (audit §4.5).

A file, not `EXTRA_TEXT`: text carriers have size limits, no media type, and
land in targets the document was not meant for.

**New dependency:** `path_provider` (BSD-3, cache directory). Justified below.

**Tests:** the fake seam records the payload; a widget test never opens a real
share sheet; cache files are written under the app-private directory and
cleaned at the next start.

### 5. Snackbar / undo helper

**Target:** `packages/design_system`

```dart
Future<void> showUndoSnackBar(
  BuildContext context, {
  required String message,      // already localized by the caller
  required String undoLabel,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 5),
});
```

The helper owns the parts that are always the same and always get subtly
wrong: dismissing a previous snackbar before showing a new one, not firing
`onUndo` twice, surviving a rebuild, and keeping the action reachable for
screen readers.

It takes **already-localized strings**. `design_system` must not depend on the
app's `AppLocalizations`, or the package stops being reusable.

The 5-second default deliberately matches the completed-task linger window
(spec 0002, VSN-201) so the two windows agree.

> **Two things found during implementation, both now guarded by tests.**
>
> 1. **`SnackBar.persist` defaults to `action != null`.** Every snackbar with
>    an action — that is, every undo snackbar — therefore *never dismisses
>    itself* in the resolved Flutter version. The helper passes
>    `persist: false` explicitly, because the trash is the real safety net
>    (a lost window costs taps, not data) and a snackbar that waits forever
>    covers the navigation bar after every completion. `persist: true` stays
>    available. Set explicitly so a Flutter upgrade cannot silently change
>    undo behaviour in every app at once.
>
> 2. **The Material row overflows at large text scales.** Message and action
>    sit in a row; at 2.0 on a 360 dp surface the action no longer fits —
>    measured at 17 px. Above `kUndoSnackBarStackThreshold` (1.5) the action
>    renders *below* the message instead. That keeps accessibility rule 5
>    without capping anybody's text size, which would defeat the point.

**Tests:** shows and dismisses; `onUndo` fires exactly once even on a double
tap; a timeout does not fire it; a second call replaces the first without
firing the first's callback; `persist` is explicitly `false`; `persist: true`
holds the snackbar; the action carries a semantic label and meets 48 dp; no
overflow at 200 %.

### 6 and 7. Markdown renderer and editor

**Target:** `packages/design_system`

This is the headline extraction. The product owner named it explicitly: every
LumbreCode app with a free-text field should have the identical text-editing
experience. WasThereSomething spec 0025 is the reference behaviour.

```dart
/// Renders Markdown source with the shared defaults.
class AppMarkdownView extends StatelessWidget {
  const AppMarkdownView({
    required this.source,
    this.contentType = kMarkdownContentType,   // text/markdown; charset=utf-8
    this.onLinkTap,                            // goes through the allowlisted seam
  });
}

/// The shared editor: formatting toolbar above, action row below.
class AppMarkdownEditor extends StatefulWidget {
  const AppMarkdownEditor({
    required this.initialText,
    required this.labels,          // AppMarkdownEditorLabels — localized by the caller
    this.onSave,                   // null hides the save button
    this.onShare,                  // null hides share
    this.maxLength,
    this.onChanged,
  });
}
```

Behaviour, from WTS spec 0025 (MDE-001..010):

- **Toolbar above:** heading (`# `), bold (`**…**`), italic (`*…*`),
  strikethrough (`~~…~~`), bullet list (`- `), clear-line-formatting.
- **Action row below:** undo, redo, reset, save, copy, share, close — each
  hideable, each disabled when unavailable.
- **Cursor-aware:** with a selection the syntax wraps it; without, it inserts
  a marker pair and places the cursor inside.
- **Undo history is per editor session, in memory.** Nothing is persisted.
- **Copy and share hand over readable plain text** with the markers stripped,
  so pasted text carries no `**` or `#`.
- **A `text/plain` body renders as plain text.** The renderer never guesses
  that plain text is Markdown.

Two constraints:

- **No new editor dependency.** A plain `TextField` plus a
  `TextEditingController`, exactly as WTS did. The formatting logic is string
  manipulation, and it is fully unit-testable that way.
- **Localized strings come in through a labels object.** `design_system` does
  not import the app's l10n.

**New dependency:** `flutter_markdown_plus` (BSD-3) for rendering only.
Justified below.

**Tests:** one widget test per toolbar button for both insert and
wrap-selection; the undo/redo/reset state machine; copy through a fake
clipboard; share through the injected seam; a `text/plain` body rendering with
visible asterisks; 200 % text scale with no overflow; every icon-only button
carrying a semantic label.

### 8. Drift hardening conventions

**Target:** `core/database/` plus the contract text

Most of this already exists and the draft underestimates the template here
(audit §2.1): `PRAGMA foreign_keys = ON`, the downgrade guard,
`addColumnIfMissing`, `wipeAllData()` in a transaction, `DriftWebOptions`, and
a migration fixture test are all present.

What slice 0 adds is **documentation**, and what slice 2 adds is the
**exercise**:

- Update `docs/architecture/contracts/02-database.md`'s "Stand im Template"
  table: rule 6 moves from partial to done once the converters land.
- Document the fixture-per-version discipline as a worked example rather than
  a rule, using the v1 → v2 step.
- Record the `@ReferenceName` trap (KI-004) as a forward-looking note: it does
  not bite today because `list_id` and `parent_task_id` point at different
  tables, and it will the moment a second edge to `tasks` appears — and the
  build still *succeeds* while silently omitting generated filters.

No code beyond the converters. Slice 2 is where foreign keys, multi-table
transactions and a chained migration first get proved.

### 9–11. Notification-related seams (slice 6, located now)

Designed in ADR-0012 and specified in spec 0003. Located here so the target
paths are decided before the pressure of the feature:

- **`core/permissions/notification_permission_gateway.dart`** — the
  template's first concrete `PermissionGateway`, implemented on the
  notification plugin's own permission API. **No permission package is added**
  (ADR-0012, decision 6).
- **`core/notifications/notification_gateway.dart`** — `schedule`, `cancel`,
  `cancelAll`, `pending`, with `FakeNotificationGateway` beside it.
- **`core/notifications/pending_actions.dart`** — the append-only queue that
  keeps the background isolate away from the domain database (ADR-0012,
  decision 4; storage choice open as spec 0003 Q-3d).

---

## Dependency justification

Required by `docs/architecture/contracts/06-library-evaluation.md`. Every
entry must be **resolved against the existing tree before adoption**
(rule 10), because this repository carries the KI-001 analyzer ceiling —
`analyzer 8.4.0`, `custom_lint 0.8.1`, `drift 2.31.0`. The draft's claim that
this template has no such lock is wrong (audit §4.1).

Both packages below are **runtime-only** and carry no analyzer constraint, so
neither should move the ceiling. That is a reason to expect success, not a
reason to skip the check.

| | `flutter_markdown_plus` | `path_provider` |
|---|---|---|
| **Purpose** | render Markdown source (component 6) | app-private cache directory for share files (component 4) |
| **Licence** | BSD-3 | BSD-3 |
| **Maintenance** | actively released; the maintained continuation of the discontinued first-party `flutter_markdown` | Flutter-team package, `flutter/packages` |
| **Platforms** | all | all; the cache path differs per platform, which is exactly why the package exists |
| **Network** | **none** — verified: it renders a string, it does not fetch. Images from a network URL are not enabled | none |
| **Abstraction** | wrapped in `AppMarkdownView`; no `features/**` file imports it | used only inside the share seam implementation |
| **Lock-in** | low — one widget behind one wrapper | low |
| **Transitive check** | resolve against the tree before adoption | resolve against the tree before adoption |
| **Removal path** | replace `AppMarkdownView`'s body with a `SelectableText` of the source — the format was chosen partly because the raw source stays readable | drop the document share seam; text sharing is unaffected |

**Deliberately not added:**

- `uuid` — fifteen lines instead (ADR-0014, library-evaluation rule 9).
- `permission_handler` — the notification plugin requests its own permission;
  one permission does not justify a permission framework (ADR-0012).
- A Markdown *editor* package — a `TextField` plus string manipulation, as WTS
  proved.
- `mime` — `descriptionContentType` parsing is a handful of lines; still open
  as spec 0004 Q-4g, leaning no.

## Components affected

| Path | Change |
|---|---|
| `packages/design_system/` | **+** Markdown renderer, Markdown editor, undo snackbar. Grows from 3 files to a real package. |
| `packages/app_core/` | **+** `Uuid4` |
| `apps/mobile_app/lib/core/domain/time/` | **new** — converters and helpers |
| `apps/mobile_app/lib/core/platform/platform_seams.dart` | **~** allowlisted `LaunchUrl` (breaking return type), **+** `ShareDocument` |
| `apps/mobile_app/lib/core/database/` | docs only in slice 0 |
| `apps/mobile_app/pubspec.yaml` | **+** `path_provider` |
| `packages/design_system/pubspec.yaml` | **+** `flutter_markdown_plus` |
| `docs/architecture/contracts/02-database.md` | **~** status table |
| `apps/mobile_app/lib/core/l10n/arb/*.arb` | **+** keys for the editor labels and the launch-refused message |

**Untouched:** `apps/mobile_app/lib/features/todos/**`. The demo keeps working
until slice 13.

## Data / Model changes

None. Slice 0 introduces the type converters but **no table and no
`schemaVersion` bump** — the converters are first used by spec 0001's slice 2,
which owns the v1 → v2 step.

## API changes

None. No backend.

## UI changes

No screen. Two new widgets in `design_system` (`AppMarkdownView`,
`AppMarkdownEditor`) and one helper (`showUndoSnackBar`), none of them routed
anywhere yet. Their first consumer is spec 0001's slice 4.

This is deliberate and worth stating for the reviewer: **slice 0 adds no
user-visible behaviour.** It is reviewable entirely against its tests.

## Tests and validation

| Component | Tests |
|---|---|
| Converters | round trip over a year including both DST transitions; impossible dates rejected; half-open interval boundary; a real Drift table round trip |
| `Uuid4` | property test over 100 000 draws: canonical form, version, variant, distinctness |
| URL seam | `http`/`https` launch; `mailto`, `file`, `javascript`, `content`, scheme-less do not, each returning `schemeNotAllowed` |
| Share seam | fake records the payload; no real share sheet in any widget test; cache files app-private and cleaned at next start |
| Undo snackbar | shows, dismisses, `onUndo` fires exactly once on a double tap, a second call replaces the first, action has a semantic label |
| Markdown renderer | Markdown renders; `text/plain` renders literally with visible asterisks; a link tap goes through the allowlisted seam; no network call |
| Markdown editor | one test per toolbar button (insert and wrap-selection); undo/redo/reset state machine; copy via fake clipboard; share via seam; 200 % text scale without overflow; semantic labels on every icon-only button |
| Package hygiene | `design_system` does not import the app's l10n; no `features/**` file imports `flutter_markdown_plus` directly |

**Commands:** `scripts/dev/quality_gate.sh`, or
`melos run analyze && melos run test`, plus `melos run codegen` producing no
diff.

**KI-005 reminders for the widget tests:** a test without an explicit locale
resolves to `en` while the template ARB is `app_de.arb` — use `wrapWithL10n`.
Do not leave a pending timer. The undo snackbar's duration means these tests
must pump deliberately rather than `pumpAndSettle` blindly.

## Risks

| Risk | Mitigation |
|---|---|
| Components get built inside `features/tasks/` "for now" | This plan names the target path per component before any code exists; the story review checklist checks it |
| The `LaunchUrl` signature change breaks the existing call site | One call site today; changed in the same story, with the test updated |
| `flutter_markdown_plus` drags an unexpected transitive constraint | Resolve against the tree before adoption (rule 10); it is runtime-only, so the KI-001 ceiling should be unaffected — verify, do not assume |
| The Markdown editor grows scope (tables, images, preview toggle) | The scope is WTS spec 0025's MDE-001..010 and nothing else; anything beyond it is a separate story |
| `design_system` accidentally depends on the app | Enforced by a test asserting no app import; the labels object exists for this reason |
| Slice 0 has no user-visible result and feels unrewarding | Stated openly above. It is what makes 3.1.0 a template change rather than an app |

## Rollout / Migration notes

- No schema change, no migration, no feature flag.
- No user-visible behaviour change. The template still runs the demo exactly
  as before.
- The `LaunchUrl` return-type change is the only breaking API change, and it
  is internal to the template.

## Story breakdown

| # | Story | Status |
|---|---|---|
| 1 | Epoch-day and minute-of-day converters in `core/domain/time/` | draft |
| 2 | `Uuid4` in `packages/app_core` | draft |
| 3 | Scheme allowlist on the URL seam, and the typed-document share seam | draft |
| 4 | Undo snackbar helper in `packages/design_system` | draft |
| 5 | Markdown renderer in `packages/design_system` | draft |
| 6 | Markdown editor with toolbar and action row in `packages/design_system` | draft |
| 7 | Database contract status update and the worked migration example | draft |

Stories 1–4 are independent and can land in any order. Story 6 depends on
story 5. Story 7 depends on story 1.

Stories live in `docs/delivery/stories/0000-shared-foundations/`.
