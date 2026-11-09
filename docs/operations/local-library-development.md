# Working with `flutter-libraries` (the `task_interchange` dependency)

The template consumes `task_interchange` from the private repository
`FlorianTim/flutter-libraries` (ADR-0017). This page covers resolving it,
developing across both repositories, and CI access.

## The dependency

`apps/mobile_app/pubspec.yaml` has one block:

```yaml
task_interchange:
  git:
    url: https://github.com/FlorianTim/flutter-libraries.git
    path: packages/task_interchange
    ref: interchange-v0.1.0
```

- **A release tag, never a branch.** The tag names the family `interchange`
  (`ijson`, `jscalendar`, `task_interchange`); all three arrive at one commit
  through relative paths inside the library checkout, so the app needs one
  block, not three.
- `pubspec.lock` records the resolved commit for all three. It is committed
  (like every lock in this repository). A tag bump is a reviewed change:
  edit `ref`, run `flutter pub get`, commit pubspec and lock together.
- Generated code of the library (Freezed) is committed there; this repository
  never runs codegen for it.
- You need read access to the repository on your machine (`git` credentials
  for GitHub) for `flutter pub get` and `melos bs` to clone it.

## Local development across both repositories

To change the library and the template together, point the workspace at your
checkout with an **untracked** `pubspec_overrides.yaml` at the **workspace
root** (this directory's top level, next to the root `pubspec.yaml`):

```yaml
dependency_overrides:
  task_interchange:
    path: C:/Workspace/FlorianTim/flutter-libraries/packages/task_interchange
  jscalendar:
    path: C:/Workspace/FlorianTim/flutter-libraries/packages/jscalendar
  ijson:
    path: C:/Workspace/FlorianTim/flutter-libraries/packages/ijson
```

- `pubspec_overrides.yaml` is in `.gitignore`. **Never commit it**: it holds a
  path on one machine and silently replaces the pinned tag.
- Before verifying the tag-pinned state (and before opening a pull request),
  delete or rename the file and run `flutter pub get`. `git status` must show
  no change to `pubspec.lock` other than an intended one.
- Overriding `task_interchange` alone is enough while the app imports only that
  package; list `jscalendar` and `ijson` as well when you import them directly.

## CI access

`flutter pub get` clones the private repository over HTTPS, which fails
without credentials.

1. Create a fine-grained personal access token with **read-only Contents** on
   `FlorianTim/flutter-libraries` and nothing else.
2. Store it as the repository secret **`FLUTTER_LIBRARIES_TOKEN`** here and in
   every derived app.
3. `ci-mobile.yml` passes it to the shared workflow:

   ```yaml
   secrets:
     git-read-token: ${{ secrets.FLUTTER_LIBRARIES_TOKEN }}
   ```

   The shared workflow rewrites the URL for that owner before `pub get`
   (`lumbrecode-engineering/docs/GITHUB_ACTIONS_ACCESS.md`). The input exists
   from `flutter-quality.yml@v1.6.0`. The moving `@v1` tag carries it since it
   advanced to v1.7.0, so `ci-mobile.yml` uses `@v1` again (see
   `docs/template-feedback/`).

> **Without the secret the job fails at `pub get`, not at start**, so it shows
> a red check. Passing the secret to a workflow version that does not declare
> it, on the other hand, makes the workflow fail to *start* and leaves no check
> run at all (KI-012). The `ci-gate` check catches that.

### Workflows that still need the token step

Only `ci-mobile.yml` uses the shared workflow. These run `flutter pub get`
themselves and will fail on the private dependency until they get the same
git-rewrite step or are moved onto a shared workflow:
`build-android.yml`, `_android-release-build.yml`, `build-ios.yml`,
`dependency-audit.yml`, `copilot-setup-steps.yml`, and the Docker-based
`integration-test.yml`. They are listed in
`docs/template-feedback/2026-10-08-pub-get-outside-the-shared-workflow.md`.
Docker runs additionally have no credentials inside the container.

## Contract test

`apps/mobile_app/test/interop/interchange_contract_test.dart` reads the golden
fixtures from `.lumbrecode/schemas/` by directory and checks decode, rejection,
round trip and unknown-property survival through the library. Run it with:

```bash
cd apps/mobile_app && flutter test test/interop
```

## Known-issues check (2026-10-08)

Adding the dependency was checked against `docs/known-issues.md`:

- **KI-001 / KI-002 / KI-009a (resolver locks):** not triggered. The solve added
  exactly three packages (`ijson`, `jscalendar`, `task_interchange`) and changed
  no existing version; the library needs only `freezed_annotation ^3.0.0` from
  the app's tree. `melos bs` bootstraps all 7 workspace packages.
- **KI-009 (pre-1.0, pin exactly, wrap):** `task_interchange` is `0.x` and
  pinned by tag (exact). The wrapping rule applies from slice 8: the app's
  data layer should reach it through an app-owned adapter directory, with an
  encapsulation test like `test/support/package_encapsulation.dart`.
- **KI-011 (Docker rewrites `package_config.json`):** applies unchanged; the
  Docker integration run also has no credentials for the private repository.
- **KI-012 (silent workflow miss):** applies to the secret input; see CI access.
- **KI-006 (signing):** unchanged, the commit is made by the human.

Observed cost: `flutter pub get` with the git dependency 10 s, `melos bs`
15 s (both with a local clone as the git source, so network time to GitHub is
not included).
