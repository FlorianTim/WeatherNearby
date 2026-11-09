# UX: In-app purchase placeholder

## The hub row

```text
PRO
 [*] Pro-Status                                    >
     Alle Funktionen sind derzeit kostenlos
```

The subtitle is doing the work. Without it, a row with a premium icon reads
as "there is something you have not paid for", which is false and which makes
a user hunt for a paywall that does not exist.

## The page

```text
+--------------------------------------------------+
| <-  Pro                                           |
+--------------------------------------------------+
| +----------------------------------------------+ |
| | [*] Kostenlose Version                        | |
| |     Alle Funktionen sind derzeit kostenlos.   | |
| +----------------------------------------------+ |
|                                                   |
| +----------------------------------------------+ |
| | [s] Store nicht verfuegbar                    | |
| +----------------------------------------------+ |
|                                                   |
|          [ Kaeufe wiederherstellen ]              |
|                                                   |
|  Diese Seite zeigt den Berechtigungsstatus.       |
|  Kaeufe sind noch nicht aktiviert.                |
+--------------------------------------------------+
```

Three states for the store row, all visibly different:

| State | Row |
|---|---|
| loading | "Store wird geprueft ..." |
| available | "Store verfuegbar" |
| unavailable | "Store nicht verfuegbar" |

The loading state is not cosmetic. Without it, a slow platform call is
indistinguishable from an unavailable store, and the first support question
about billing is always "it says unavailable, is that a bug?".

## Restore

A `restorePurchases()` call has exactly three outcomes, each with its own
message:

| Outcome | Message |
|---|---|
| nothing to restore | "Keine Kaeufe gefunden." |
| entitlement restored | "Pro wurde wiederhergestellt." |
| call failed or no store | "Der Store ist derzeit nicht erreichbar." |

Restore stays on the page and never navigates.

## What is deliberately absent

No price, no product list, no buy button, no "upgrade" call to action, and no
comparison table. The page's job today is to be honest about a state, not to
sell. Every one of those elements arrives with the real adapter — and each
one is a store-review surface that must not exist before it works.

## Accessibility

- The status card is one semantics node: icon decorative, title and subtitle
  merged by `ListTile`.
- The store state is carried by its text, never by the icon colour alone.
- The restore button is at least 48 dp tall and keeps its label while the
  call runs; a spinner replaces the label only for the duration of the call,
  with the button disabled so it cannot be pressed twice.
