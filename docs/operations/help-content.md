# Help content and screenshots

One source, two renderings. The manual and the FAQ are authored once under
`docs/public-site/` and end up in two places: bundled inside the app, and
published on the app's public website.

```text
docs/public-site/
  faq/{de,en}.yaml              the FAQ, validated against the shared schema
  guides/{de,en}/*.md           the manual, one file per guide, ordered
  screenshots.yaml              which screenshots the documentation may use
  screenshot-profiles.json      the screen sizes the capture flow renders at
        │
        ├──▶ the public website
        └──▶ apps/mobile_app/assets/help/{manual,faq}_{de,en}.md   GENERATED

design/screenshots/<profile>/<id>.png   written by the screenshot flow
```

## Why it is not hand-written any more

Until this pipeline existed, the in-app FAQ and the website FAQ were two
files with the same content. They drifted inside a single release, and the
in-app copy was the one nobody noticed was stale — nobody reads their own
app's help.

The screenshots had the mirror problem. The template could already produce
them (`integration_test/app_screenshots_test.dart`, see
`docs/operations/screenshots.md`), and no document referenced them. A capture
run proved nothing, and a stale image could never have been caught.

## Regenerating

```bash
python -m pip install -r requirements.txt   # once
python .lumbrecode/tooling/docs/render_app_help.py \
    --repo . --target app \
    --out apps/mobile_app/assets/help \
    --pattern '{document}_{locale}.md'
```

The renderer is this repository's **only** Python dependency — everything
under `scripts/automation/` uses the standard library. Without it, the `help`
step of the quality gate fails with the install command in its message.

## The documentation is generated in CI

Two workflows own the generated output on `main`:

| Workflow | Produces |
|---|---|
| `integration-test.yml` | the screenshots, committed into `design/screenshots/` |
| `help-generate.yml` | the bundled help, committed into `apps/mobile_app/assets/help/` |

A developer edits `docs/public-site/`. The workflows own everything derived
from it — the same arrangement the glossary already has.

Add `--check` to verify without writing. That form is already wired in:

| Where | Behaviour |
|---|---|
| `scripts/dev/quality_gate.sh` / `.ps1` | step `help` |
| `scripts/validate.sh` | `==> Generated help` |

Both skip the step when `.lumbrecode/` is absent, so a checkout that has not
run the baseline sync can still run its gate — and both fail when a generated
file was edited by hand. That is fast feedback on a branch, not a second
authority: if the gate and the workflow ever disagree, the workflow is what
lands on `main`.

> The tool is synchronized from `lumbrecode-engineering` into
> `.lumbrecode/tooling/docs/` and committed here, per the baseline model:
> a local agent finds it in the current checkout without needing access to
> the private repository.

## Referencing a screenshot

In a guide or an FAQ answer:

```markdown
{{screenshot:02-settings}}
```

The id must be declared in `docs/public-site/screenshots.yaml` with a caption
per locale. What the placeholder becomes depends on where it is rendered:

| Target | Result |
|---|---|
| public website | `![caption](…)` |
| bundled in-app help | the caption, as plain text |

**The app deliberately drops the image.** `AppMarkdownView` refuses to
resolve external references — a body may have arrived from an imported
document, so nothing is ever fetched. That restriction is a security
property, not an omission, and the caption carries the meaning instead.

## Adding a screenshot

1. Capture it in the flow: add a `_shot(...)` step in
   `integration_test/app_screenshots_test.dart`. The screen sizes come from
   `docs/public-site/screenshot-profiles.json` — a shared contract with the
   web template — and are passed in as dart-defines, so the test holds no
   list of its own.
2. Declare it in `docs/public-site/screenshots.yaml` with a caption in every
   locale, describing the screen rather than repeating the file name.
3. Reference it from a guide or an FAQ answer.
4. Re-render.

A reference to an undeclared id fails immediately, and a declared id whose
image is missing fails too — the template's own screenshots are captured and
committed, so this is a hard failure rather than a warning.

`optional: true` downgrades a single shot to a warning. Use it only for a
screen CI genuinely cannot reach, such as one behind a device capability or
a granted permission — never to quiet a shot whose capture step is simply
missing.
