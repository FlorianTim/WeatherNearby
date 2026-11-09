# Open questions: Settings hub, in-app help and privacy page

## Resolved during specification

### Q1 — Does "delete app data" stay on the hub, or move to the privacy page?

**Decided: it moves.** Keeping it in both places duplicates a destructive
action, and a duplicated destructive action eventually diverges in wording,
in confirmation text, or in what it actually clears. The privacy page is
where a user goes with the question that leads to deletion ("what do you
store about me?"), so the answer and the action belong together — which is
also how the reference app does it.

The hub row that leads there names the outcome in its subtitle, so
discoverability is not lost.

### Q2 — Sub-pages for language and appearance, or inline on the hub?

**Decided: inline.** Both are short lists with a "follow the device" default,
and language is the most-used setting in a bilingual app. Sub-pages would add
two routes, two pages and two test files to save about eight rows of
scrolling.

### Q3 — Bundled Markdown, or l10n keys, for the help documents?

**Decided: bundled Markdown assets.** ARB is for interface strings; a manual
is prose with structure, and putting it in ARB means escaping every newline
and losing every heading. The renderer already exists (`AppMarkdownView`), so
the asset route costs nothing extra.

### Q4 — Does the intro-replay row live in help, or in development?

**Decided: help.** Re-reading the introduction is something a user does on
purpose, not a debugging affordance. The development section is for things
that must not exist in a release build.

## Still open

### Q5 — Should the diagnostics page be able to copy its content?

A support case is easier when the user can paste their settings state into a
mail. Against it: the raw state can contain values a user does not expect to
share, and the bug mail already carries app version and device facts.

**Proposal:** revisit when the first real support case needs it. Not
blocking; the page is debug-only, so nobody outside development sees it yet.

### Q6 — How does a derived app declare its permission overview?

Today the router passes a list literal. Once two or three apps exist, a
declarative `AppPermissions` register — the same shape as `AppSettings` —
would probably earn itself.

**Proposal:** wait for the second real permission (spec 0003 brings the
first). Registering a pattern from one example is how a register ends up
fitting exactly one caller.
