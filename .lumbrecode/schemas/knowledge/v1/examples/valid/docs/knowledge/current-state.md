---
type: application
id: app.sample
app_id: app.sample
title: Sample — current state
description: Fixture application with a calendar.
status: current
generated: true
repository: FlorianTim/sample
revision: 0123abc
app_version: 0.3.0
lifecycle: prototype
verification: code-verified
last_verified: 2026-10-16
platforms: [android, web]
derived_from: template.flutter-app-template
capabilities: [cap.calendar-management]
screenshots: [shot.sample.01-home]
relationships:
  - type: derived_from
    target: template.flutter-app-template
    evidence: GENERATED_FROM_TEMPLATE
  - type: implements
    target: cap.calendar-management
    via: impl.sample.calendar
sources:
  - kind: doc
    ref: README.md
  - kind: code
    ref: lib/features/calendar/
    revision: 0123abc
---

# Sample — current state

See the [README](../../README.md) and the
![home screen](../../design/screenshots/phone-portrait/01-home.png).

Contact: support@example.com
