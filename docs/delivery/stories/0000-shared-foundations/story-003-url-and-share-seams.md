# Story: URL scheme allowlist and the typed-document share seam

## Metadata

- **Status:** ready
- **Feature:** none — template surface. Plan:
  `docs/delivery/implementation-plans/0000-shared-foundations.md`,
  components 3 and 4
- **Target release:** 3.1.0 (`now`)

## Goal

Make the URL seam refuse every scheme except `http`/`https`, and add a seam
for sharing a typed document file.

## Context

`core/platform/platform_seams.dart` already defines `LaunchUrl`, `ShareText`
and `CopyToClipboard` as injectable typedef providers. Two gaps block the
reference app:

1. **`urlLauncher` has no allowlist.** It hands any `Uri` to
   `url_launcher.launchUrl`. The interop contract (§2.7, §10.7) requires that
   only `https:` and `http:` ever launch, because link targets in an imported
   document are user-entered URLs from an untrusted source. Enforcing that at
   every call site is how it gets forgotten — and the app is about to acquire
   call sites that render foreign documents.
2. **`ShareText` shares text only.** The contract requires a **file**, not
   `EXTRA_TEXT`: text carriers have size limits, no media type, and land in
   targets the document was not meant for (guide §6.1).

Both are security-relevant and identical in every app, so both are template
surface.

## Scope

- `LaunchOutcome` enum (`launched`, `schemeNotAllowed`, `failed`).
- `LaunchUrl` changes to `Future<LaunchOutcome> Function(Uri)`; the provider
  checks the scheme **before** calling the plugin.
- `kAllowedUrlSchemes` as a named constant.
- `SharePayload` value type and the `ShareDocument` typedef seam, with a
  `@Riverpod(keepAlive: true)` provider writing to the app-private cache and
  calling `share_plus` 12.x.
- Cache directory access via `path_provider` (**new dependency**).
- A `fireAndForget` startup task that clears the share cache.
- ARB keys for the "cannot open this link" message.
- Update the one existing `LaunchUrl` call site.

## Out of scope

- Building any document. Spec 0004's slice 9 owns that.
- The `ShareText` seam — unchanged.
- A UI for showing a non-openable link. Spec 0001's slice 4 owns it; this
  story only makes the outcome available.
- iOS or web share behaviour beyond what the seam already degrades to.

## Relevant files

- `apps/mobile_app/lib/core/platform/platform_seams.dart`
- `apps/mobile_app/lib/core/startup/startup_providers.dart` — the cache-clear
  task
- `apps/mobile_app/pubspec.yaml` — `path_provider`
- `docs/architecture/contracts/06-library-evaluation.md`
- `docs/delivery/reviews/2026-08-25-template-readiness-todo-reference-app.md`
  §4.5 — the verified `share_plus` 12.x signature

## Correction found during implementation

The story as written assumed a single blanket `http`/`https` allowlist and
"one existing call site". Both were wrong against the code:

- **`mailto:` is already used by the template.** `FeedbackMailBuilder` builds
  a prefilled support mail, launched through this seam from **two** call
  sites (`about_page.dart`, `startup_error_page.dart`). A blanket allowlist
  would have broken the feedback path.
- The interop contract's rule is about links from an **untrusted document**,
  not about every URI the app itself constructs.

So the allowlist is a **policy the caller names**, with the restrictive one as
the default: `UrlPolicy.webOnly` (`http`, `https`) and
`UrlPolicy.appAuthored` (adds `mailto`). Forgetting to pass a policy yields
the safe behaviour. The acceptance criteria below reflect this.

## Acceptance criteria

- [ ] `https://…` and `http://…` reach the underlying plugin and return
      `LaunchOutcome.launched`.
- [ ] Under the default `UrlPolicy.webOnly`, `mailto:`, `tel:`, `file:`,
      `javascript:`, `content:`, `intent:`, `data:`, `ftp:`, `sms:` and a
      scheme-less URI each return `schemeNotAllowed` **without** the plugin
      being called.
- [ ] `UrlPolicy.appAuthored` permits `mailto:` and nothing beyond
      `http`/`https`/`mailto`.
- [ ] The default is `webOnly`, so omitting the policy is the safe choice.
- [ ] A test asserts neither allowlist has been widened.
- [ ] Scheme comparison is case-insensitive (`HTTPS://` is allowed).
- [ ] A plugin failure returns `failed`, not an exception.
- [ ] The existing call site compiles against the new return type and behaves
      as before for `https`.
- [ ] `ShareDocument` writes a UTF-8 file under the app-private cache
      directory, in a `share/` subdirectory, and calls
      `SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: …)]))`.
- [ ] The seam is a provider, so a widget test can override it and no real
      share sheet opens.
- [ ] A `fireAndForget` startup task deletes the share cache directory's
      contents, and is safe when the directory does not exist.
- [ ] `path_provider` is the only new dependency, and `cross_file` is **not**
      added.

## Test requirements

- `test/core/platform/url_allowlist_test.dart` — the allow and reject table,
  case-insensitivity, the `failed` path, and an assertion that the plugin fake
  records **zero** calls for every rejected scheme.
- `test/core/platform/share_document_test.dart` — the fake seam records the
  payload; the real implementation writes under the cache dir with the right
  file name and media type.
- `test/core/startup/share_cache_cleanup_test.dart` — clears an existing
  directory; no-ops on a missing one.
- Commands: `flutter test`, `flutter analyze`,
  `scripts/dev/quality_gate.sh`.

## Documentation requirements

- Doc comment on `LaunchUrl` stating that the allowlist is a **security**
  boundary, with the interop-contract reference — so nobody widens it for
  convenience.
- Doc comment on `ShareDocument` stating "a file, not `EXTRA_TEXT`", and why.
- Note the `share_plus` 12.x signature and that the interop guide's 10.x
  snippet does not compile here.

## Implementation notes

- **Verified against the resolved packages** (`share_plus 12.0.2`,
  `share_plus_platform_interface 6.1.0`): `ShareParams` takes
  `List<XFile>? files` and `List<String>? fileNameOverrides`. `XFile` is
  re-exported from `package:share_plus/share_plus.dart`, so **no `cross_file`
  dependency is needed**. `Share.shareXFiles(...)` from the guide is the 10.x
  API and does not exist here.
- The return-type change on `LaunchUrl` is breaking, deliberately. One call
  site exists today; changing it now is cheaper than adding a safe variant
  next to an unsafe one.
- Resolve `path_provider` against the existing tree **before** adding it
  (library-evaluation rule 10). It is runtime-only and should not move the
  KI-001 analyzer ceiling — verify, do not assume.
- Regenerate with `melos run codegen` after touching the annotated providers;
  never edit `platform_seams.g.dart`.

## Review checklist

- [ ] Scope maintained
- [ ] Acceptance criteria fulfilled
- [ ] Tests present and passing
- [ ] Exactly one new dependency, justified in the PR
- [ ] Generated files regenerated, not hand-edited
- [ ] `features/todos/` untouched
