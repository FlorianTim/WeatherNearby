# OpenSpec — App specifications for template initialization

This directory holds the machine-readable app specification used by the
**template initializer** (`.github/agents/template-initializer.agent.md`) to
create a new LumbreCode app from this template.

It complements — and does not replace — the feature-level spec workflow under
`docs/product/specs/`. OpenSpec answers "what app is this?"; feature specs
answer "what does the app do in detail?".

## Rule

> For every new app generated from this template, create or provide an
> OpenSpec entry that defines at least: `app_name`, `app_display_name`,
> `app_slug`, `short_description`, `primary_platforms`, `backend_enabled`,
> `core_features`, `privacy_requirements`, `security_requirements`,
> `splash_screen_app_name`, `replace_todo_app`.

## Layout

```
openspec/
  README.md                     This file
  templates/app.openspec.yaml   Template for new app specs
  apps/todoapp.openspec.yaml    Spec of the built-in Todo example app
```

## Package name derivation

The Android application id / package name is derived from `app_slug`:

```
de.lumbre.code.<app_slug>
```

`app_slug` must therefore be:

- lowercase letters, digits, underscores only
- starting with a letter
- a valid Android application id segment AND a valid Dart package name

Examples: `badmintonscheduler`, `passwallet`, `eventmanager`.

## Todo example app

The Todo app under `apps/mobile_app/lib/features/todos/` is a deliberate part
of the template (smoke test, Riverpod/generator/test reference). It is only
removed or replaced when:

1. a concrete new app spec exists under `openspec/apps/`, AND
2. the task explicitly says to initialize that new app, AND
3. `replace_todo_app: true` is set (or unambiguously derivable from the task).

## Validation checklist (before `apply`)

- [ ] All required fields present and non-empty
- [ ] `app_slug` matches `^[a-z][a-z0-9_]*$`
- [ ] `app_slug` not equal to a reserved word (`test`, `flutter`, `dart`)
- [ ] `backend_enabled` decided (and backend flavor: `node` or `dart`)
- [ ] `replace_todo_app` explicitly set
- [ ] `splash_screen_app_name` set (company splash always stays "LumbreCode")
- [ ] Privacy/security requirements reviewed (privacy-by-default)
