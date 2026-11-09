# Open questions: App intro (onboarding)

## Resolved during specification

### Q1 — Reset the flag, or open the intro immediately?

**Decided: open it immediately.** "Show the intro again" that shows nothing
until the next app start is a surprising affordance, and it cannot be
verified by a widget test without restarting the app. The reference app's
reset semantics exist because its intro is followed by a setup assistant that
only makes sense at startup; the template has no such follow-up.

### Q2 — Does the intro keep the language choice, or does it move to settings only?

**Decided: the intro keeps it.** Removing it would be a regression: today the
template's very first screen lets a user pick a language before reading
anything. Keeping it inside the intro preserves that and demonstrates the
option tiles at the same time.

### Q3 — How many pages?

**Decided: five.** Fewer cannot cover welcome, data handling and the language
choice with a closing page. More is a template asking a new user to read
documentation before seeing the app.

### Q4 — What happens if writing the flag fails?

**Decided: the user leaves anyway** (ONB-031). A storage failure must not be
able to trap someone in a modal flow. Seeing the intro again next start is a
recoverable annoyance; being unable to reach the app is not.

## Still open

### Q5 — Should a major version bump be able to re-show the intro?

A "what's new" flow (out of scope here) would need a stored version marker
and per-version content. Whether it reuses this pager or gets its own is
undecided.

**Proposal:** revisit when the first derived app ships its second major
version and actually has something to announce.

### Q6 — Does the intro belong in front of the splash rather than behind it?

Showing it before the branded splash would get a new user to the content
faster, but it would also mean the first thing a user sees is not the brand.

**Proposal:** keep it behind the splash. Revisit only if startup work grows
long enough that the splash becomes a wait rather than a moment.
