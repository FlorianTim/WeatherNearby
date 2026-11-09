# UX: App intro (onboarding)

## Shape

```text
+--------------------------------------------------+
|                                 [ Ueberspringen ] |
|                                                   |
|                    ( icon )                       |
|                                                   |
|              Willkommen bei ...                   |
|                                                   |
|        Zwei, drei Zeilen, die sagen,              |
|        wofuer die App da ist.                     |
|                                                   |
|                                                   |
|                 *  o  o  o  o                     |
|                                                   |
|            [        Weiter        ]               |
+--------------------------------------------------+
```

The last page's button reads "Los geht's" instead of "Weiter". That, not the
indicator, is what tells a user they are at the end — the dots are too small
to carry that meaning, and a screen reader does not announce them at all.

## The five pages

| # | Icon | Says |
|---|---|---|
| 1 | waving hand | What the app is, in one sentence. |
| 2 | list | What you can do with it. |
| 3 | lock | Where the data lives: on this device, nothing is uploaded. |
| 4 | language | Language and appearance, choosable right here. |
| 5 | rocket | That it is ready, and where to find help and settings later. |

Page 3 is not decoration. It is the same promise the privacy page makes
(spec 0005, SET-030), said once at the point where a new user is deciding
whether to trust the app.

## Page 4 — language and appearance

Renders the same `AppOptionTile` rows as the settings hub, inside the pager:

```text
                 ( icon )
          Sprache und Darstellung

  SPRACHE
   (o) Systemsprache
   ( ) Deutsch                                DE
   ( ) English                                EN

  ERSCHEINUNGSBILD
   (o) Systemeinstellung
   ( ) Hell
   ( ) Dunkel
```

A tap takes effect immediately — the intro itself switches language and
theme under the user's finger. That is the demonstration; a preview would be
weaker and cost more code.

This page scrolls independently of the pager so that a large text scale
cannot overflow it.

## Reopening from settings

The settings hub row "App-Einleitung erneut anzeigen" pushes the intro on top
of the current screen. Finishing or skipping returns to settings. Nothing is
reset — reopening is reading, not starting over.

The reference app deliberately differs here: it clears the flag so the intro
returns on the *next* start. Opening it now is the more direct reading of
"show it again", and it is testable without restarting the app.

## Accessibility

- Skip is a `TextButton` in the top-right, at least 48 dp tall, present on
  every page.
- The primary action is a full-width `FilledButton`.
- Page icons are decorative and excluded from semantics.
- The indicator carries no semantics node; the button label communicates
  progress instead.
