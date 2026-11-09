# Screenshot management

> IDs, paths and values in the examples on this page are illustrative. They
> are not facts about the named application.

Applications produce their own screenshots. This skill **discovers, selects,
references and occasionally copies** them. It never generates, edits, crops or
re-encodes a screenshot, and it requires no particular generator, file name or
image size.

## Discovery

1. **Manifests first.** The LumbreCode screenshot contract is
   `docs/public-site/screenshots.yaml` (schema
   `.lumbrecode/schemas/screenshots/v1/manifest.schema.json`: `id`, localized
   `caption`, `profiles`, `optional`) plus `screenshot-profiles.json`, with
   images in `design/screenshots/<profile>/<id>.png`. When present, consume
   it as-is — its IDs and captions are authoritative.
2. **Then directories**, if no manifest exists or it is incomplete:
   `design/screenshots/`, `assets/screenshots/`, `docs/screenshots/`,
   `docs/images/`, `fastlane/metadata/**/images/`, `store/`, Playwright or
   integration-test output folders the repository commits.
3. **Ignore** build output that is not committed, test failure diffs
   (`*-diff.png`, `*-actual.png`), icons, launcher art and mockups — mockups
   (`design/mockups/`, Stitch exports) are To-Be, not As-Is.

## Analysis per image

For each candidate, determine without modifying it:

| Question | How |
|---|---|
| Which screen? | manifest caption, file name, image content |
| Which feature? | match to `feat.*` IDs from the feature catalog |
| Current? | `git log -1 --format=%h,%cs -- <file>` versus the last commit that changed the screen's code; a screen changed after its image → `outdated` |
| Duplicate? | same id across profiles is not a duplicate; same screen under two ids is |
| Platform, size, locale, theme | profile, image dimensions, manifest, file name |

## Selection

Do not import everything. Pick the smallest set that lets another agent see
the product — typically 5–10 for an app, more only for a complex one:

1. main screen, 2. primary navigation, 3. core feature screens,
4. representative workflows, 5. important settings, 6. distinctive reusable
components, 7. screens showing platform capabilities (sharing, notifications,
camera).

Prefer the primary profile; add another profile only where layout genuinely
differs (tablet two-pane, desktop).

## Index entry

The app's screenshot index (`screenshots.yaml` in drafts; `screenshots.md`
centrally) holds one entry per selected image:

```yaml
- id: shot.packzeit.01-home          # stable; reuse the manifest id
  app_id: app.packzeit
  feature: feat.packzeit.packing-lists
  screen: Home — trip overview
  description: Upcoming trips with packing progress per trip.
  source: design/screenshots/phone-portrait/01-home.png
  repository: FlorianTim/Packzeit
  revision: bda390a                  # last commit touching the file
  app_version: 1.4.0
  created: 2026-10-08                # from git or file metadata
  platform: android
  profile: phone-portrait
  size: 412x915
  locale: en
  theme: light
  drive_file_id: null                # only after a verified upload
  verification: current              # current | outdated | unverified
  privacy: synthetic-data            # synthetic-data | reviewed | needs-review
```

Use relative paths for repository files and only **verified** Drive links for
copied assets. Never embed images as base64.

## Privacy gate

Before proposing an image for publication, look at it. Reject or mark
`needs-review` when it shows names, e-mail addresses, phone numbers, real
addresses, tokens, keys, account IDs, customer or production data, or private
calendar or contact content. Prefer images produced by the app's capture flow
with demo data. If no safe image exists, record a request for a sanitized
capture from the app's own screenshot mechanism — do not alter the original.
`outdated` and `needs-review` images are never published automatically.

## Copy versus reference

Default: **reference** the repository file.

Copy into Drive only when a permanent snapshot is needed, the source will not
stay accessible, a release needs its own visual record, or Drive readers have
no repository access. If the Drive connector cannot upload images, keep the
reference, set `drive_file_id: null`, and list the upload as pending in the
change set. Never report an upload that readback did not confirm.
