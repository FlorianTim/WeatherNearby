# No place for a menu bar or keyboard shortcuts, and the Windows build was undocumented for them

- **Date:** 2026-10-01
- **Area:** App shell
- **Severity:** `friction`
- **Template version:** 3.2.1
- **Status:** resolved in spec 0008

## Observed

`build-windows.md` describes a Windows build, and the web build runs in desktop
browsers, but the shell had no menu bar, no way to reach a screen from the
keyboard and no quit entry. Each derived app would have invented its own.

## Root cause

The shell was designed as a phone app (settings hub, intro, about); desktop was
a build target without a UI consequence.

## Change made

`core/menu/` (menu as data, `AppMenuHost` with a native, a Flutter and no
bar) and `app/menu/` (the app's entries, commands, route-aware scope). Flutter
has no native menu on Windows and Linux; ADR-0016 records that the bar is
drawn by Flutter there.

## What would catch a recurrence

The menu tests pin the platform (`debugDefaultTargetPlatformOverride`), so a
new platform value in `AppMenuStyle.detect` fails until it is given a style.
