# ADR-0013: The Android receive boundary for JSCalendar documents

## Status

proposed

## Date

2026-08-25

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `docs/product/specs/0004-jscalendar-interoperability/`
- Contract: `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` 6.2, 9.3, 10
- Envelope: `lumbrecode-engineering/docs/LUMBRECODE_EXCHANGE.md`
- Slice 8 of `docs/delivery/implementation-plans/0001-todo-reference-app.md`
- `docs/architecture/contracts/05-external-data-ownership.md`

## Related issues / PRs

- none yet

## Context

The reference app is the *receiving* half of a contract whose sending half
already exists (WasThereSomething 1.5). A user shares a task list from one
app and picks this one in the Android share sheet; a document arrives; tasks
appear.

That is a security boundary. Everything crossing it is attacker-controlled in
the general case: the app cannot know which app produced a document, and
`prodId` and CloudEvents `source` are explicitly documented as *claims, never
trust decisions*. The interop guide's 6.2/6.4 and 10.12 are written as rules
precisely because each of them is a way to get this wrong.

Three things make this decision non-obvious in *this* repository, and the
third is the one that will trip an implementer.

1. **The filter must be narrow.** The obvious `receive_sharing_intent`
   README configuration asks for broad filters and storage permission. A
   `*/*` or `text/plain` filter would put a to-do app in every share sheet on
   the device — for photos, for links, for anything.

2. **The parsing must be total.** Guide 5.5 and 10.12: a rejected document
   writes zero rows. That means the parse/validate stage cannot be
   interleaved with persistence, which constrains the architecture, not just
   the error handling.

3. **`apps/mobile_app/android/` does not exist in this repository.** Verified.
   The Android project is produced by `scripts/bootstrap_android.sh` on
   demand; the only Android artefacts under version control are
   `scripts/bootstrap/android-res/` and the manifest patcher
   `_apply_backup_policy` inside `scripts/lib/apply_android_branding.sh`
   (with a PowerShell twin, `scripts/lib/Apply-AndroidBranding.ps1`).

   Every description of this work in the interop guide and in the planning
   draft says "edit `AndroidManifest.xml`". Following that literally here
   produces a change that works on the author's machine and vanishes on the
   next bootstrap.

## Decision

1. **The receive path is an app-owned platform channel in `MainActivity`,
   not `receive_sharing_intent`.**

   Roughly 80 lines of Kotlin whose entire surface is: read the `Intent`,
   hand the `Uri` (as a string) to Dart, mark it consumed. No third-party
   code sits in the security-critical path, no README-suggested broad filter
   can creep back in on a package update, and no `READ_EXTERNAL_STORAGE` is
   ever requested. This mirrors what WasThereSomething chose for the event
   receive path and for the same reason: the boundary is small and
   security-relevant, so owning it is cheaper than auditing someone else's.

2. **The manifest change is delivered as a bootstrap patch, not as a
   committed file.** A function `_apply_receive_intent_filter` is added
   alongside `_apply_backup_policy` in `scripts/lib/apply_android_branding.sh`,
   and mirrored in `scripts/lib/Apply-AndroidBranding.ps1`. It is idempotent
   (a second run detects the filter and leaves it alone) and it fails loudly
   if the manifest is not where it expects it. What it injects:

   ```xml
   <!-- into <activity android:name=".MainActivity"> -->
   <intent-filter>
     <action android:name="android.intent.action.SEND" />
     <category android:name="android.intent.category.DEFAULT" />
     <data android:mimeType="application/jscalendar+json" />
   </intent-filter>
   <intent-filter>
     <action android:name="android.intent.action.SEND_MULTIPLE" />
     <category android:name="android.intent.category.DEFAULT" />
     <data android:mimeType="application/jscalendar+json" />
   </intent-filter>
   ```

   plus `android:launchMode="singleTop"` on the activity, so the warm path
   goes through `onNewIntent`.

   Exactly these two MIME entries. **Never `*/*`, never `text/plain`.**
   Android matches the *base* media type, so one entry covers both
   `;type=task` and `;type=group`.

   `application/cloudevents+json` is deliberately **not** registered as a
   separate filter in v1: the envelope arrives through the same share action
   from a sibling LumbreCode app, and the decoder sniffs the payload shape
   (`@type` versus `specversion`+`data`) after reading. Adding a second MIME
   filter widens the share-sheet surface for no user-visible gain. Revisit if
   a sender ever declares only the CloudEvents type.

3. **Read is capped, single-source and stream-based.** The bytes come from
   `ContentResolver.openInputStream(uri)` on the URI the intent delivered,
   and from nothing else. A hard **256 KiB** cap is enforced *while reading*,
   not after: the reader stops at the cap and the document is rejected as
   oversized. No path derived from document content is ever opened.

4. **An intent is consumed exactly once.** The activity clears the intent's
   payload extras after handing them to Dart and records a consumed marker
   keyed on the delivery, so rotation, back navigation and process restore
   cannot re-trigger an import. If a second payload arrives while an import
   review is open, it is **queued** — two review screens must never stack.

5. **Import review has no bypass and no setting.** Parse and validate first,
   collect typed warnings, then show what will be created and everything that
   was lost. Only on confirmation does a single transaction write the list and
   its tasks. A payload is a proposal, never a command. There is no
   "auto-import" preference, and adding one later requires a new ADR.

6. **The receive path never requests a runtime permission.** If something in
   it appears to need one, the design is wrong.

7. **Nothing is fetched.** No `href` from an imported document is resolved,
   previewed, size-checked or opened automatically — not for a favicon, not
   for a thumbnail. `http:`/`https:` open only on an explicit user tap,
   through the allowlisted URL seam introduced in slice 0. Every other scheme
   is displayed and not launched.

8. **A familiar `uid` is provenance, never a merge.** A `Group` always becomes
   a **new list**, even on a second import of the identical file. The app may
   warn ("you imported a list with this name on 25 August"); it may never act
   on the resemblance. This is the interop guide's most emphatic rule and it
   is what keeps sharing a hand-off rather than a distributed-state problem.

9. **Logging records counts and reason codes only.** Never a title, a body, a
   `uid` or a file name.

## Alternatives considered

| Alternative | Pro | Contra |
|---|---|---|
| **`receive_sharing_intent` 1.9** | Works out of the box; handles cold and warm; Android and iOS | A third-party plugin in the security-critical path; its documented setup asks for broad filters and `READ_EXTERNAL_STORAGE`, both of which must be trimmed and then *kept* trimmed across upgrades. The plugin is also pre-1.0-adjacent in API stability, which triggers KI-009's pin-and-wrap rules. For ~80 lines of Kotlin, the dependency does not pay. |
| **Committing `android/` so the manifest can be edited normally** | Manifest edits become ordinary file edits | Contradicts a deliberate template decision: `android/` is not committed because it would carry a stale application id into every derived app. Reversing that for one intent filter is the tail wagging the dog. |
| **A separate `<activity-alias>` for the receive path** | Cleaner separation; can be disabled independently | A second exported component to reason about, and the payload still has to reach the same Dart isolate. `singleTop` on `MainActivity` is the smaller boundary. |
| **Registering `*/*` and sniffing content** | Catches senders that mislabel their MIME type | Puts the app in every share sheet on the device. A category of bad citizenship, and a much larger attack surface for zero verified benefit. |
| **Auto-import for documents from a known `sourceappid`** | Fewer taps for the common LumbreCode-to-LumbreCode case | `sourceappid` is a claim, not authentication (exchange profile rule 4). Auto-import on an unauthenticated claim is precisely the hole the review screen exists to close. |
| **Registering `application/cloudevents+json` as a second filter now** | Explicit about the second supported channel | Widens the share-sheet surface with no gain: the same share action delivers it, and the decoder sniffs the shape. Revisit when a sender declares only that type. |

## Consequences

### Positive

- The security-critical surface is small, owned and readable in one sitting.
- No new runtime dependency for the receive path.
- The share sheet stays honest: the app appears only for documents it can
  actually read.
- Total import means a rejected document cannot leave half a list behind.
- The Kotlin side is thin enough that the interesting logic (parse, validate,
  warn, review, persist) is pure Dart and fully unit-testable.

### Negative

- Android-only. iOS receive would need its own share extension and is out of
  scope; the app declares Android as its only primary platform.
- The Kotlin side is not covered by `flutter test`. It needs either an
  instrumentation test or a documented manual test-plan entry (cold start,
  warm delivery, rotation during review, two payloads in a row). The plan
  chooses the manual entry plus a Dart-side test of everything downstream of
  the channel.
- The bootstrap patcher is a second place where "the manifest" lives, and it
  has to stay in sync between the bash and the PowerShell implementation. A
  test that greps the generated manifest after a bootstrap would catch drift,
  but only on a machine that runs the bootstrap.
- A user who mislabels a document (shares `.json` as `text/plain` from a file
  manager) will not see the app in the share sheet. That is the intended
  trade; the app also offers no "open file" path in v1, which is worth
  revisiting if it turns out to be a common complaint.

## Test and validation impact

- Dart-side unit tests own everything after the channel: byte-cap rejection,
  malformed JSON, envelope unwrapping, batch unwrapping, tolerant decoding,
  warning collection.
- Integration tests own the transaction properties: CT-11 (a `uid` seen twice
  creates two lists) and CT-12 (a rejected document leaves zero rows).
- A fuzz test feeds truncated, oversized and randomly mutated documents; no
  input may produce an unhandled exception (interop guide 12.3).
- Manual test-plan entries: cold start with a payload, warm delivery through
  `onNewIntent`, rotation while the review is open, a second payload arriving
  during review, and a document one byte over the cap.
- A grep-level check that no `lib/` file outside the interop feature imports
  the channel, in the spirit of the package-encapsulation test the template
  already uses.

## Follow-up tasks

- Add `_apply_receive_intent_filter` to both branding scripts, with an
  idempotency guard, in slice 8.
- Extend `scripts/bootstrap/android-res/README.md` with the manifest-patch
  table, so the next reader finds the intent filter where they find the
  backup policy.
- Add the manual test-plan entries to `docs/testing/manual-test-plans/`.
- Decide, when a second app in the family receives documents, whether the
  channel code becomes a shared package or stays copied. Copied is fine for
  two.

## References

- `lumbrecode-engineering/docs/JSCALENDAR_TASK_INTEROP.md` 6.2, 6.3, 6.4,
  9.3, 10, 12
- `lumbrecode-engineering/docs/LUMBRECODE_EXCHANGE.md` — reading rules
- `docs/architecture/contracts/05-external-data-ownership.md`
- `docs/known-issues.md` KI-009
- `scripts/lib/apply_android_branding.sh`, `scripts/bootstrap/android-res/README.md`
- WasThereSomething ADR-0016 (Android event receive boundary) — the precedent
  this mirrors for tasks
