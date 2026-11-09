# `openspec/apps/` holds two example entries and the classification names one

- **Date:** 2026-08-27
- **Area:** Initialization
- **Severity:** `papercut`
- **Template version:** 3.2.1
- **Status:** resolved in 3.2.1

## Observed

The classification says to delete `openspec/apps/todoapp.openspec.yaml`. The
folder contains two files:

```
openspec/apps/todo.openspec.yaml       7247 bytes
openspec/apps/todoapp.openspec.yaml    1224 bytes
```

`openspec/README.md` documents only `todoapp.openspec.yaml`. An initializer
that follows the instruction literally leaves the larger of the two behind, in
the folder that is supposed to describe **this** app — where it reads as the
new app's spec.

## Root cause

`todo.openspec.yaml` was added with the 3.1.0 reference-app planning and
neither the classification nor the OpenSpec README was updated. Two files, one
mention, and no rule that says the folder holds exactly one entry.

## Change made

Both entries are named in the deletion list.

## What would catch a recurrence

Stating the invariant instead of the file names: **after initialization,
`openspec/apps/` contains exactly one entry, and it is the new app's.** That
survives someone adding a third example.
