# ADR-0016: Bounded screenshot integration checks on pull requests

## Status

accepted

## Date

2026-09-29

## Context

The screenshot workflow previously ran only after a push to `main`. A derived
app exposed a browser test that stopped after the settings screenshot and
remained active until GitHub canceled the job after six hours. The screenshot
helper also caught every error, which could hide a missing image in a driver
run. A pull request could therefore merge without testing this flow.

The template also uses screenshots as inputs for its published documentation.
On `main`, the workflow commits captured images and creates handbook release
assets. Those outputs are part of the template's existing publication path.

## Decision

- Run the integration workflow on pull requests when the app, screenshot flow,
  Docker runner, screenshot contract, or workflow changes.
- On pull requests, upload the report and screenshots as short-lived Actions
  artifacts. Only non-PR runs (`push` to `main` or manual dispatch) may commit
  screenshots or create a release.
- Bound the job to 30 minutes, each screen profile to eight minutes, and each
  screenshot request to 30 seconds. Log each request and completion.
- The screenshot driver passes `SCREENSHOT_DRIVER=true`; failures in that mode
  fail the test. Plain widget test runs may skip screenshot capture.
- Assert the destination screen and scroll navigation targets into view before
  capturing the next screen.

## Consequences

Pull requests now show screenshot failures before merge. A stalled profile
ends with a diagnostic instead of occupying a runner for hours. The template's
existing `main` publication behavior remains available. Derived private apps
may choose a stricter artifact-only policy, as TrainMedia does.

## Evidence

TrainMedia PR #2 completed all nine declared screenshots across three screen
profiles after the bounded flow was introduced (Actions run 36535613261).
