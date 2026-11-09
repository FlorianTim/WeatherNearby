# Known issues & traps

Problems that already cost real debugging time, with the evidence and the
exact retry condition. **Read this before starting a dependency upgrade or
debugging a "weird" test failure** — most entries look like a bug in your
own change at first glance.

Portable by design: this file travels with the template into every app
derived from it. When an app hits a new trap, add it here **and** upstream
it into the template.

Conventions: each entry has a stable `KI-xxx` id, a status
(`blocking` / `active` / `resolved`) and — where applicable — a
**retry condition** that must be true before trying again.

Origin: entries KI-001 … KI-009 were harvested from the first app built on
this template (*WasThereSomething*, releases 1.0 → 1.3.1). Where an entry
names that app's packages, it is kept as a worked example — the underlying
rule is what matters.

---

## KI-001 — Dependency lock: drift ≥ 2.32 forces riverpod 3.3.x, which breaks widget tests

**Status:** blocking (verified 2026-07-23, still applies to this template)
· **Area:** dependencies

### Symptom

After upgrading `drift`/`drift_dev` to the 2.34 line, widget tests fail
deterministically with:

```
setState() or markNeedsBuild() called during build.
This UncontrolledProviderScope widget cannot be marked as needing to build …
```

The stack goes through `_UncontrolledProviderScopeState.scheduleRefresh`
→ `ProviderScheduler._scheduleRefreshTask` → `ProviderElement.flush` →
`ProviderSubscriptionImpl.resume`. App code is unchanged; only tests fail.

### Root cause (the actual trap)

It is **not** a drift problem and not fixable by pinning drift alone — it
is a transitive version lock through the Dart analyzer:

```
drift_dev >= 2.32.1   →  analyzer >= 10        (>= 2.34.1+1 needs analyzer ^13)
custom_lint 0.8.1     →  analyzer ^8.0.0       ← blocks drift_dev >= 2.32
riverpod_generator >= 4.0.4-dev.1 → analyzer ^12
```

So: **new drift ⇒ new analyzer ⇒ new riverpod_generator ⇒ a newer riverpod
runtime.** There is no combination of the new drift toolchain with the older
riverpod runtime — verified repeatedly, including via
`dependency_overrides` (the resolver rejects every mix).

### Evidence

- Old stack (`drift 2.31.0`, `flutter_riverpod 3.1.0`): the canary tests
  **pass** — checked in a clean worktree.
- New stack (`drift 2.34.2`, `flutter_riverpod 3.3.2`, codegen re-run): the
  same tests **fail**, app code unchanged.
- The riverpod `master` changelog carries an **unreleased** entry
  *"Fix markNeedsBuild exception when flushing a provider inside Widget
  lifecycle"*; related: [riverpod#4381][ki001-issue]. The failure is
  attributed to that bug — matching symptom, stack and timing — but the fix
  itself was not test-verified (unreleased at the time of writing).

### How to check whether it is fixed

| Link | What it tells you |
|---|---|
| [pub.dev: flutter_riverpod versions][ki001-versions] | **The release gate.** Is there a version > 3.3.2? |
| [flutter_riverpod CHANGELOG on `master`][ki001-changelog-fr] | Whether *"Fix markNeedsBuild exception when flushing a provider inside Widget lifecycle"* has moved out of **Unreleased** |
| [riverpod#4381][ki001-issue] | Closest match to the symptom: passes on 2.6.1, fails from 3.0.3 — app works, only tests fail |
| [riverpod#4661][ki001-issue-4661] | Same regression family (the commit fixing `markNeedsBuild` caused `setState` after `dispose`) |
| [pub.dev: sqlite3_flutter_libs][ki001-sqlite-pub] | The EOL half of this entry: `0.6.0+eol` "no longer does anything"; guidance is to move to `package:sqlite3` 3.x |
| [pub.dev: drift_flutter][ki001-drift-flutter] | Whether `drift_flutter` still pulls `sqlite3_flutter_libs` transitively (it does in 0.3.1) |

### Consequence for this template

`sqlite3_flutter_libs` stays in the dependency list **although it is
end-of-life**. This is accepted technical debt, not an oversight.

### Retry condition

A `flutter_riverpod` version **> 3.3.2** is published containing the
`markNeedsBuild`/widget-lifecycle fix. Do not start the upgrade before
that — you will re-derive this analysis and revert again.

### Upgrade recipe (applies cleanly; only the tests fail today)

1. `apps/mobile_app/pubspec.yaml`: `drift: ^2.34.0`, `drift_dev: ^2.34.0`,
   `drift_flutter: ^0.3.1`, add `sqlite3: ^3.4.0`, drop the direct
   `sqlite3_flutter_libs`, drop `custom_lint`, `riverpod_lint: ^3.1.4`.
2. Move the analyzer plugin declaration — see [KI-002](#ki-002).
3. `melos run codegen`.
4. Refresh the web database assets:
   `cd apps/mobile_app && dart run tool/sync_web_database_assets.dart`.
   It re-copies `web/sqlite3.wasm` from the resolved drift package and
   recompiles `web/drift_worker.js` against it; the manual sources are the
   [sqlite3.dart releases][ki001-sqlite] (tag = resolved `sqlite3` version)
   and the [drift releases][ki001-drift] (tag = resolved `drift` version).
   **Stale wasm fails only at runtime on web, never in CI.**
5. Verify: `melos run analyze`, `bash scripts/dev/test_summary.sh`,
   `flutter build apk --debug`.

[ki001-issue]: https://github.com/rrousselGit/riverpod/issues/4381
[ki001-issue-4661]: https://github.com/rrousselGit/riverpod/issues/4661
[ki001-versions]: https://pub.dev/packages/flutter_riverpod/versions
[ki001-changelog-fr]: https://github.com/rrousselGit/riverpod/blob/master/packages/flutter_riverpod/CHANGELOG.md
[ki001-sqlite-pub]: https://pub.dev/packages/sqlite3_flutter_libs
[ki001-drift-flutter]: https://pub.dev/packages/drift_flutter
[ki001-sqlite]: https://github.com/simolus3/sqlite3.dart/releases
[ki001-drift]: https://github.com/simolus3/drift/releases

---

## KI-002 — riverpod_lint ≥ 3.1.4 dropped custom_lint; `plugins:` must sit in the workspace root

**Status:** active · **Area:** tooling

`riverpod_lint` 3.1.4+ runs on the native `analysis_server_plugin` system
instead of `custom_lint`. Two traps:

- `custom_lint` is no longer needed **and** actively blocks newer analyzer
  versions (see [KI-001](#ki-001)). Remove it together with the
  `analyzer: plugins: - custom_lint` entry.
- The replacement is a **top-level** `plugins:` key and it must live in the
  **pub workspace root** `analysis_options.yaml`. Putting it in
  `apps/mobile_app/analysis_options.yaml` yields:
  `Plugins can only be specified in the root of a pub workspace …`
  (`plugins_in_inner_options`).

```yaml
# analysis_options.yaml (workspace root)
plugins:
  riverpod_lint: ^3.1.4
```

**This template is still on the old layout** — `apps/mobile_app/analysis_options.yaml`
declares `analyzer: plugins: - custom_lint`. That is deliberate: the move is
part of the KI-001 upgrade, not a separate change.

### Windows legacy-client workaround (2026-09-29)

The workspace lockfile holds `riverpod_lint` 3.0.3. A broad `^3.0.0` constraint
can let the generated `custom_lint_client` independently resolve 3.1.x, which
no longer provides the legacy entrypoint. Pin the app dev dependency to the
already locked 3.0.3. On Windows, `scripts/dev/analyze.ps1` gives each Flutter
analysis a fresh temporary directory so a stale generated client in the
shared user temp directory is not reused. The PowerShell quality gate calls
this wrapper. The permanent native-plugin migration remains part of KI-001.

**Reference:** [pub.dev: riverpod_lint][ki002-pub] documents the install via
`analysis_options.yaml` and states the package is built on
`analysis_server_plugin`, not custom_lint (verified 2026-07-23, v3.1.4).
[pub.dev: custom_lint][ki002-custom] shows the analyzer ceiling
(`analyzer ^8.0.0` in 0.8.1) that makes it incompatible with newer
`drift_dev`.

[ki002-pub]: https://pub.dev/packages/riverpod_lint
[ki002-custom]: https://pub.dev/packages/custom_lint

---

## KI-003 — Drift `watch()` only re-emits for tables that are part of the query

**Status:** active · **Area:** persistence

**Symptom:** the UI shows stale data after writing to a side table; the
value is correct after a manual reload. In widget tests it looks like a
missing `pumpAndSettle`.

**Cause:** drift derives the stream's invalidation set from the tables the
query actually touches. Loading a related table **inside** `.asyncMap(...)`
hides it from that set, so writes to it never trigger a re-emit.

```dart
// WRONG — edits to the related table never refresh the stream
query.watch().asyncMap((rows) async {
  final note = await _noteOf(row.id);   // invisible to drift
  …
});

// RIGHT — join it, then read it off the row
_db.select(_db.items).join([
  leftOuterJoin(_db.notes, _db.notes.itemId.equalsExp(_db.items.id)),
]);
```

**Rule of thumb:** *everything the emitted object depends on must be in the
query.*

---

## KI-004 — Drift API and lint pitfalls (codegen)

**Status:** active · **Area:** persistence

| Trap | Fix |
|---|---|
| `Variable.withString('x')` no longer exists | `Variable<String>('x')` |
| Test imports `package:drift/drift.dart` → `isNull`/`isNotNull` clash with `package:matcher` | `import 'package:drift/drift.dart' hide isNull, isNotNull;` |
| Column `.check()` self-reference trips the `recursive_getters` lint | `// ignore: recursive_getters` above the getter **and** the expression |
| Two FKs from one table to the same target → codegen warning, filters/orderings silently not generated | annotate both with `@ReferenceName('…')` |
| A `TypeConverter` declared on the wrong side (e.g. epoch days on `dateTime()`) | declare it on the **storage** type: `integer().map(const EpochDayConverter())` |
| Generated part fails with `Couldn't find constructor 'XConverter'` | import the converter into the **database library** file, not only into the table file |

The `@ReferenceName` case is the only one where drift points at its own
docs from the build output:
<https://drift.simonbinder.eu/docs/manager/#name-clashes>. It is easy to
miss because **the build still succeeds** — it just silently omits the
generated filters/orderings for that field.

---

## KI-005 — Widget-test environment gotchas

**Status:** active · **Area:** testing

Most of these are already handled by `test/support/test_app.dart`. They are
listed here so nobody "simplifies" the harness and reintroduces them.

- **`rootBundle` caching across FakeAsync zones:** `rootBundle` caches
  `loadString` futures per asset key. A future cached in an earlier test's
  zone never completes when awaited from the next test — the test just
  hangs. Fix: `setUp(rootBundle.clear)` in asset-loading tests.
- **`await someDriftStream.first` in a `testWidgets` body deadlocks** under
  FakeAsync. Do DB setup and assertions inside
  `tester.runAsync(() async { … })`.
- **Drift's multiple-database warning timer** trips flutter_test's
  pending-timer invariant, because each widget test builds its own instance
  on purpose: set
  `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true`.
- **Drift's zero-duration close timers** fire while the `ProviderScope`
  disposes. Unmount and pump once after the test body:
  `await tester.pumpWidget(const SizedBox.shrink()); await tester.pump(const Duration(milliseconds: 1));`
- **Lazy `ListView`s do not build offscreen children.** Use a finite phone
  profile and `scrollUntilVisible` for interaction tests. Tall surfaces are
  appropriate only for explicitly labelled whole-content inspections.
- **The bottom navigation bar swallows taps** on targets that are only
  edge-visible. Unfocus first (a focused field scrolls itself back into view
  and silently undoes the drag), then drag the scrollable, then tap.
- **Widget tests without an explicit locale resolve to `en`**, but the ARB
  template is `app_de.arb`. Use `wrapWithL10n(child)` — it defaults to `de`.
- **Grid UIs must be tested on a phone-sized surface.** A month grid derives
  its row capacity from the row height; a desktop-sized test surface
  silently exercises a different code path.

---

## KI-006 — Commit signing is interactive; agents cannot commit

**Status:** active · **Area:** tooling

Commit signing is enabled (`gpg`), and signing prompts for the passphrase
via `pinentry`. In a non-interactive agent shell this always ends in:

```
gpg: signing failed: Timeout
error: gpg failed to sign the data
fatal: failed to write commit object
```

The pre-commit format hook runs *before* this and succeeds, so the failure
looks like a hook problem but is not.

**Rule:** agents stage the change and hand the finished commit message to
the human, who commits and pushes. Never work around it with
`--no-gpg-sign` / `-c commit.gpgsign=false` unless the human explicitly
asks.

---

## KI-007 — Delegating to preview LLM models hangs

**Status:** active · **Area:** tooling

`opencode run --model google/gemini-3.1-pro-preview` did not return within
3+ minutes even for a trivial prompt ("reply OK"), while
`google/gemini-3.6-flash` answered the same prompt in ~8 s. Requests do
reach the API, which points at a retry loop against the preview quota
rather than a misconfiguration.

**Rule:** delegate to a flash/stable model by default. Before using a
preview model for a long task, smoke-test it:

```bash
opencode run --model <model> "Reply with exactly the word OK and nothing else."
```

Kill leftover processes before retrying — a hung run holds the repo.

No upstream ticket was filed: the symptom is environment-dependent
(quota/model availability) and may disappear on its own. Re-test with the
smoke command before assuming it still applies.

---

## KI-008 — Drift stores `DateTime` with second precision

**Status:** active · **Area:** persistence

Drift persists `DateTime` as unix **seconds** by default. Two consequences,
both hit for real:

1. **Tests:** a value written with `DateTime.now()` comes back without
   milliseconds. Comparing against the original fails
   (`2026-07-30 00:52:05.711521` vs `2026-07-30 00:52:05.000`). Fix:
   truncate the expected value to whole seconds.
2. **Ordering:** two rows can carry the same timestamp, so
   `ORDER BY <timestamp>` is not deterministic. This happened with a
   synchronization log: an app-start run and an import run easily finish
   inside the same second. Fix: add a monotonic insertion counter column and
   sort by that; keep the timestamp for display and retention.

**Rule:** if the order of two rows matters to the domain, do not rely on a
`DateTime` as the sort key.

---

## KI-009 — Pre-1.0 packages: pin exactly, wrap, and check the transitive tree first

**Status:** active · **Area:** dependencies

Two failure modes that only show up after a package is already in use.
Worked example from *WasThereSomething*: the calendar UI package `kalender`
and the calendar access package `device_calendar`.

### (a) Two packages can be mutually unresolvable through a shared transitive dependency

```
Because kalender >=0.15.1 depends on timezone ^0.11.0 and device_calendar 4.3.3
depends on timezone ^0.9.0, kalender >=0.15.1 is incompatible with
device_calendar 4.3.3.
```

`device_calendar` had not shipped a release in ~2 years, so the *newer*
package had to be pinned to an old version. A `dependency_overrides` on
`timezone` was **rejected**: the older package would then run against an
untested major, and a break would surface only on a device, never in CI.

**Rule:** before adopting a package, resolve its constraints against the
existing tree — not after.

### (b) A pre-1.0 package ships breaking changes in minor releases

`kalender` announced breaking changes in minor releases and required four
behavioural corrections in the app's adapter (agenda scrolled to the range
start instead of the focused date; month cells hid every entry behind
"N more" at the default tile height; the package set its visible range
during `initState`, causing `markNeedsBuild`; the month header overflowed on
phone widths).

**Rules:**

1. **Pin exactly** (no caret) and record the retry/upgrade condition.
2. **Wrap it** behind an app-owned adapter directory and app-owned boundary
   types, so a swap touches two files.
3. **Enforce the wrapper with a test** that scans `lib/` and fails on any
   import outside the adapter directory — the architecture rule alone
   erodes. See `test/support/package_encapsulation.dart`.
4. Before every version bump: read the changelog for breaking changes and
   repeat the manual device pass.

---

## KI-010 — Android launch background: `drawable-v21/` wins, `drawable/` does not

**Status:** active · **Area:** android

`flutter create` generates the launch screen **twice**:

| File | Generated content |
|---|---|
| `res/drawable/launch_background.xml` | `@android:color/white` |
| `res/drawable-v21/launch_background.xml` | `?android:colorBackground` |

The `-v21` qualifier wins on **every device from API 21 upward**, which in
practice means every device. Branding only `drawable/` therefore changes
nothing visible: the launch window keeps showing the system background — white
in light mode — before the first Flutter frame.

The failure mode is the nastiest kind: the file you edited is correct, the
value you set is correct, and the resource you edited is simply never read.
Nothing warns you.

**Fix:** brand `drawable-v21/launch_background.xml` as well. The templates
under `scripts/bootstrap/android-res/` carry both, and
`apply_android_branding` copies both.

**Related trap in the same family:** on Android 12+ the splash attributes live
in `values-v31/styles.xml`, and a `values-night/styles.xml` without a matching
`values-night-v31/` wins in dark mode and silently drops them. Same shape:
a more specific qualifier quietly overrides the file you branded.

**Rule of thumb:** after changing an Android resource, check whether a more
specific qualifier folder (`-v21`, `-v31`, `-night`, density variants) holds
the same file name.

## KI-011 — The Docker integration run rewrites the host's package config

**Status:** active · **Area:** tooling, integration tests

`scripts/dev/screenshots.sh auto` and `scripts/build.sh integration-web` run
`flutter pub get` **inside** the container, against the mounted workspace.
That rewrites `apps/mobile_app/.dart_tool/package_config.json` with container
paths (`/workspace/...`), which the host cannot resolve.

The failure afterwards looks nothing like its cause:

```text
error - Target of URI doesn't exist: 'package:flutter_test/flutter_test.dart'
2791 issues found.
```

Every import in the package appears broken at once, including files nobody
touched. The natural reading is "my change broke the build" — it did not.
The tell is the count: a real regression does not produce thousands of
`uri_does_not_exist` errors across untouched files.

**Fix:** re-run `flutter pub get` on the host.

```bash
cd apps/mobile_app && flutter pub get
```

**Rule of thumb:** after any Docker-based Flutter task, run `flutter pub get`
on the host before trusting the analyzer. The same applies to
`flutter analyze <subdirectory>` — analyzing a folder as if it were its own
package root produces the identical symptom.

---

## KI-012 — A workflow that fails to start produces no check run, and the PR looks clean

**Status:** active · **Area:** CI

A workflow whose *call* cannot be resolved fails before it starts any job.
GitHub attaches no check run to the pull request, so the PR shows no red
check — and no check at all. It reports `MERGEABLE` / `CLEAN`.

Evidence, from PR #24 of this repository:

```text
run 33019633490   conclusion: failure   jobs: 0   duration: 0s
PR #24 statusCheckRollup: no entry from that run
```

The cause was a `uses:` pointing at a reusable workflow that could not be
resolved. Every ref mistake has this shape: wrong tag, deleted tag, renamed
file, or no access to the workflow's repository.

**Why branch protection does not fix it here.** A required status check would
turn "missing" into "blocked". Both branch protection and rulesets need
GitHub Pro or a public repository, and this template is a private repository
under a personal account — the API answers `403 Upgrade to GitHub Pro`.

**What is in place instead:** `.github/workflows/ci-gate.yml` runs on every
pull request with no path filters and asserts that each gating workflow
actually produced a run for the head commit. A silent miss becomes a red
`gate (…)` check.

**What it cannot do:** block a merge. Nothing can, without branch protection.
Treat a green PR as evidence only when the `gate` check is among the green
ones.

**Retry condition:** if the repository ever moves to GitHub Pro or becomes
public, set the real required check and keep the gate as a second opinion:

```bash
gh api -X PUT repos/OWNER/REPO/branches/main/protection/required_status_checks   -f strict=true -f 'contexts[]=mobile-quality / quality'
```
