# `drafts/init/` — the input for a new app

Everything the new app is built **from** goes here: its description, notes,
mockups, icons and any other raw material.

This folder is the one exception to the drafts rule in two directions:

| | Rest of `drafts/` | `drafts/init/` |
|---|---|---|
| Read by the initializer? | no | **yes — it is the input** |
| Deleted when a new app is generated? | yes | **no** |
| Normative? | no | no — specs derived from it are |

## What goes where

| Folder | Content |
|---|---|
| `spec/` | The app description in whatever form it arrived: a requirements document, a mail, a voice-note transcript, a one-pager |
| `notes/` | Loose thoughts, decisions taken in conversation, things to remember |
| `mockups/` | Screen designs, wireframes, Stitch exports, screenshots of comparable apps |
| `icons/` | App icon artwork, adaptive layers, brand assets |
| `resources/` | Everything else: colour palettes, fonts, example data, API documentation of a service the app talks to |

Formats are free. Markdown, PDF, PNG, ZIP — whatever the material came as.

## How it is used

1. You drop the material in here.
2. The initializer reads it and runs the **plan & spec phase**
   (`docs/operations/template-initialization.md`): one OpenSpec entry under
   `openspec/apps/`, plus one feature spec per feature under
   `docs/product/specs/`.
3. Those specs are reviewed and become binding. **The material here never
   does** — if a detail matters, it has to end up in a spec.
4. Icons and mockups are moved to where they belong: app artwork to
   `apps/mobile_app/assets/`, design references to `design/`.

## When it can be deleted

**Only when everything in it has been processed** — every requirement is in
a spec, every asset is where the build expects it, and nothing here is the
only copy of anything.

Deleting it is the last step of initialization, not the first. Until then it
survives every cleanup, including the one that empties the rest of `drafts/`.

Track what has been processed in `processed.md` next to this file, so a
half-finished initialization can be picked up later.
