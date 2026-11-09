# Mobile app agent instructions

## Scope

These instructions apply to `apps/mobile_app/`.

## Example app

This template ships with a runnable **example app**:
splash (two-phase) → language picker → greeting, plus a **Todo feature**
(`lib/features/todos/`) with Riverpod (generator-based), Freezed models,
Drift persistence, go_router and tests.

The Todo app is the reference implementation and smoke test of the template.
**Do not delete it during general template maintenance.** The example app is
replaced only by the template initializer
(`.github/agents/template-initializer.agent.md`) in `apply` mode with a
concrete app spec and `replace_todo_app: true`. See
`docs/operations/template-initialization.md`.

### Files replaced during app initialization (initializer `apply` mode only)

| File / Folder | Action | Notes |
|---------------|--------|-------|
| `lib/features/todos/` | **Replace** | Reference feature — keep as style guide until the new app's first feature exists |
| `lib/features/greeting/` | **Delete** | Purely an example |
| `lib/features/settings/` | **Replace** | Replace with real settings feature |
| `lib/features/splash/` | **Adapt** | Company phase (LumbreCode) STAYS; app phase gets the new app name |
| `lib/core/database/` | **Adapt** | Remove todo tables, keep Drift setup |
| `lib/core/l10n/arb/` | **Update** | Replace todo/example strings; run `flutter gen-l10n` |
| `lib/core/l10n/generated/` | **Do not edit** | Auto-generated from ARB files |
| `test/`, `integration_test/` | **Rewrite** | Keep the test style, adapt to real features |
| `pubspec.yaml` | **Update** | `name`, `description`, `version`, dependencies |
| `lib/app/router/` | **Adapt** | Keep go_router + `app_router.dart` pattern |
| `lib/app/bootstrap.dart` | **Keep / extend** | Add DI, logging, crash reporting here |
| `lib/main.dart` | **Keep** | Entry point — usually stays |

### What always stays

- `lib/app/bootstrap.dart`, `lib/main.dart`
- The two-phase splash concept and the LumbreCode company splash phase
- Local Lottie placeholder assets (`assets/animations/`, replace per app)
- `packages/design_system`, `packages/app_core`
- The `lib/features/<name>/<layer>/` structure
- The l10n setup (`l10n.yaml`, ARB files, generated code)

## Internationalisation (i18n)

- Use Flutter's standard `flutter_localizations` + ARB files.
- ARB source files live in `lib/core/l10n/arb/`.
- Generated code lives in `lib/core/l10n/generated/` — **never edit by hand**.
- The `l10n.yaml` config uses `synthetic-package: false` (required for workspace mode).
- After editing ARB files, run: `flutter gen-l10n`
- Access strings via `AppLocalizations.of(context)`.
- The template locale for new keys is `app_de.arb` (German).
- Date/time formatting uses `intl` `DateFormat` with the current `Locale` — this automatically
  produces locale-correct output (e.g. `MM/dd/yyyy` for `en_US`, `dd.MM.yyyy` for `de`).

## Structure

- Keep app bootstrapping in `lib/app/`.
- Keep cross-feature infrastructure in `lib/core/`.
- Keep product functionality under `lib/features/<feature>/`.
- Keep truly shared widgets in `lib/shared/`.

## Code style

- Use Dart triple-slash doc comments (`///`) — this matches the existing code.
- Extract deeply nested widget subtrees into private `StatelessWidget` classes
  within the same file to keep build methods shallow.

## UI rules

- Prefer composition over large widget files.
- Keep business logic out of widgets.
- Use the design system package before introducing one-off UI primitives.

## UI pitfalls (base patterns — follow from day one)

- **Toolbar/editor widgets next to a `TextField`**: wrap the whole group in a
  `TextFieldTapRegion`. Without it, tapping a toolbar button on web/desktop
  collapses the text selection to -1 and inserted text lands at the end:

  ```dart
  return TextFieldTapRegion(child: Column(children: [toolbar, textField]));
  ```

- **FABs in multiple shell branches** need unique `heroTag`s
  (`FloatingActionButton(heroTag: 'fab-today', ...)`) — otherwise pushing a
  root route crashes with a Hero conflict.
- **Navigating from a root route back into a shell branch**: always
  `context.go(...)`, never `context.push(...)` — pushing re-enters the shell
  and corrupts the navigation stack.

## Testing conventions

- Use the **test harness** (`test/support/test_app.dart`): `TestAppHarness`
  wires an in-memory database, in-memory key-value store, fake plugin seams
  and short splash timing (1 s / 1 s → `pumpPastSplash` reaches the shell).
- Wrap single widgets with `wrapWithL10n(widget)` — it defaults to locale
  `de` because the ARB template is `app_de.arb`. Widget tests without an
  explicit locale would otherwise resolve to `en` and fail on German strings.
- Never call plugins directly from widgets — read the seam providers in
  `lib/core/platform/platform_seams.dart` and override them in tests.
- **Drift + FakeAsync gotcha**: `await someDriftStream.first` directly in a
  `testWidgets` body deadlocks. Do DB setup/asserts inside
  `tester.runAsync(() async { ... })`.
- Lazy `ListView`s don't build offscreen children — for long lists set a
  tall viewport: `tester.view.physicalSize = const Size(1080, 3600);`.

## State rules

- Riverpod is the project standard (ADR-0008). Use it for new state.
- Create new providers with `riverpod_annotation` + `riverpod_generator` —
  do not hand-write provider boilerplate.
- Keep providers testable; override them in tests via `ProviderScope`
  overrides (see `test/features/todos/` for the reference pattern).
- Keep business logic out of widgets — put it in notifiers/repositories.
- Do not mix in other state-management frameworks without a new ADR.
