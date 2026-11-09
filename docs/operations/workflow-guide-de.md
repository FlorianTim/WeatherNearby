# Workflow-Anleitung: Idee bis Code

Diese Anleitung beschreibt den vollständigen Entwicklungsprozess in diesem Repository —
von der ersten Idee bis zum fertigen Pull Request.

---

## Inhaltsverzeichnis

1. [Überblick](#überblick)
2. [Simple Idea Inbox](#simple-idea-inbox)
3. [Triage: Ideen sortieren](#triage-ideen-sortieren)
4. [Feature-Kandidaten](#feature-kandidaten)
5. [Feature-Spezifikation erstellen](#feature-spezifikation-erstellen)
6. [Architekturprüfung](#architekturprüfung)
7. [Implementierungsplan](#implementierungsplan)
8. [Stories erstellen](#stories-erstellen)
9. [Implementierung (Code schreiben)](#implementierung-code-schreiben)
10. [Pull Request erstellen](#pull-request-erstellen)
11. [Review](#review)
12. [Nach der Umsetzung](#nach-der-umsetzung)
13. [Skills und Agents nutzen](#skills-und-agents-nutzen)
14. [Copilot Coding Agent beauftragen](#copilot-coding-agent-beauftragen)
15. [Häufige Fehler vermeiden](#häufige-fehler-vermeiden)

---

## Überblick

Dieses Repository unterstützt zwei Arbeitsweisen:

| Modus | Wann? | Ergebnis |
|-------|-------|----------|
| **Simple Idea Inbox** | Schnelle Ideen unterwegs, per Handy, Obsidian, Diktat | Dokumentierte, triagierte Ideen |
| **Spec-first Workflow** | Größere Features, die Planung brauchen | Spezifikation → Plan → Stories → Code |

### Kernregel

```
Rohideen         → nur lesen und sortieren, KEIN Code
Feature-Kandidat → bewerten und priorisieren, KEIN Code
Spezifikation    → Anforderungen klären, KEIN Code
Plan             → technischen Ansatz planen, KEIN Code
Story            → HIER darf Code entstehen (wenn Status: ready)
```

### Status-Modell

Eine Idee durchläuft diese Zustände:

```
raw → triaged → candidate → specified → planned → ready → implementing → implemented → archived
```

Zusätzlicher Endzustand: `rejected`

### Release-Lanes

| Lane | Bedeutung |
|------|-----------|
| now | Wird gerade aktiv bearbeitet |
| next | Kommt direkt danach |
| v1, v2, v3 | An eine Version gebunden |
| later | Richtung klar, Zeitpunkt offen |
| someday | Interessant, aber unverbindlich |

---

## Simple Idea Inbox

### Was ist das?

Eine einfache Markdown-Datei, in die du jederzeit Ideen schreiben kannst.
Kein Formalismus, keine Pflichtfelder — einfach aufschreiben.

### Wo?

```
docs/ideas/simple/ideas.md
```

### Wie benutzen?

Öffne die Datei und schreibe deine Idee unter die aktuelle Datumsüberschrift:

```markdown
### 2026-06-15

- [v2] Push-Benachrichtigungen für Termine
- [ux] Onboarding-Screen ist zu lang, auf 3 Schritte kürzen
- [tech] SQLite statt SharedPreferences für Offline-Daten prüfen
- [question] Brauchen wir einen Dark Mode für v1?
- [bug] Kalender scrollt nicht zurück zum heutigen Tag
```

### Tags (optional)

Tags helfen bei der späteren Triage:

- `[now]`, `[next]`, `[v1]`, `[v2]`, `[v3]`, `[later]`, `[someday]` — Release-Lane
- `[ux]`, `[tech]`, `[bug]` — Kategorie
- `[question]` — Offene Frage, kein Feature
- `[discard?]` — Wahrscheinlich nicht relevant

### Anhänge

Bilder, Skizzen oder Screenshots kommen nach:

```
docs/ideas/simple/attachments/
```

### Wichtig

- Diese Datei ist NUR eine Inbox.
- Aus dieser Datei wird NIEMALS direkt Code geschrieben.
- Copilot darf die Datei lesen und triagieren, aber nicht implementieren.

---

## Triage: Ideen sortieren

### Was passiert bei der Triage?

Neue Ideen werden gelesen, bewertet und einsortiert:

- Duplikate werden zusammengeführt
- Offene Fragen werden gesammelt
- Vielversprechende Ideen werden zu Feature-Kandidaten
- Die Roadmap wird bei Bedarf aktualisiert

### Wie?

**Option A: Manuell**

1. Öffne `docs/ideas/simple/ideas.md`
2. Lies neue Einträge
3. Bewerte: Ist das ein echtes Feature? Eine Frage? Ein Bug?
4. Trage Ergebnisse in `docs/ideas/triage/idea-triage.md` ein
5. Erstelle Feature-Kandidaten in `docs/product/feature-candidates.md`
6. Aktualisiere `docs/ideas/simple/processed-index.yml`

**Option B: Mit Copilot / Agent**

Nutze den Triage-Prompt aus `docs/delivery/agent-prompts.md` (Abschnitt A):

```
Lies docs/ideas/simple/ideas.md und docs/ideas/simple/processed-index.yml.
Verarbeite nur neue oder geänderte Ideen.
Ändere die Rohideen-Datei NICHT.
Aktualisiere: Triage-Ergebnisse, Feature-Kandidaten, Roadmap, processed-index.
Implementiere NICHTS.
```

Oder nutze den Skill: `.github/skills/simple-idea-triage/SKILL.md`

### Beispiel: Triage-Ergebnis

Nach der Triage könnte `docs/ideas/triage/idea-triage.md` so aussehen:

```markdown
## Letzter Triage-Stand

Datum: 2026-06-15
Commit: abc1234

## Erkannte neue Ideen

1. Push-Benachrichtigungen für Termine → Feature-Kandidat (v2)
2. Onboarding kürzen → Feature-Kandidat (next)
3. SQLite prüfen → Architektur-Frage, ADR nötig
4. Dark Mode → Offene Frage: Priorität unklar
5. Kalender-Bug → Direkt als Bug-Issue anlegen

## Offene Fragen

- Dark Mode: Ist das v1 oder später?
- SQLite: Brauchen wir Offline-Sync oder nur lokalen Cache?

## Empfohlene nächste Schritte

1. Bug-Issue für Kalender-Scroll anlegen
2. Feature-Kandidat "Onboarding kürzen" weiter spezifizieren
3. ADR-Bedarf für SQLite klären
```

---

## Feature-Kandidaten

### Was ist ein Feature-Kandidat?

Ein Feature-Kandidat ist eine Idee, die als vielversprechend eingestuft wurde,
aber noch nicht detailliert spezifiziert ist.

### Wo?

```
docs/product/feature-candidates.md
```

### Beispiel

```markdown
### Push-Benachrichtigungen für Termine

- **Status:** candidate
- **Source:** docs/ideas/simple/ideas.md (2026-06-15)
- **Target release:** v2
- **Priority:** medium
- **Confidence:** low

#### Raw input

"Push-Benachrichtigungen für Termine"

#### Interpreted intent

Nutzer sollen vor anstehenden Terminen per Push erinnert werden.

#### User value

Nutzer verpassen keine Termine mehr, auch wenn die App geschlossen ist.

#### Possible scope

- Lokale Benachrichtigungen (kein Backend nötig)
- Konfigurierbare Vorlaufzeit (z.B. 15min, 1h, 1 Tag)
- Ein/Aus pro Termin

#### Out of scope

- Server-Side Push
- Benachrichtigungs-Gruppierung
- Rich Notifications mit Bildern

#### Open questions

- Welche Vorlaufzeiten sind sinnvoll?
- Sollen Benachrichtigungen auch im Nicht-Stören-Modus kommen?
- Brauchen wir iOS-Berechtigungsdialoge speziell gestalten?

#### Architecture impact

- Neues Package für lokale Benachrichtigungen nötig (flutter_local_notifications?)
- Hintergrund-Scheduling auf Android/iOS unterschiedlich
- Möglicher ADR für Notification-Strategie

#### Test considerations

- Unit-Tests für Scheduling-Logik
- Widget-Tests für Einstellungs-UI
- Manueller Test auf echtem Gerät (Emulator zeigt keine Push)

#### Recommendation

Erst in v2 angehen. Vorher ADR zur Notification-Strategie schreiben.
```

---

## Feature-Spezifikation erstellen

### Wann?

Wenn ein Feature-Kandidat reif genug ist und tatsächlich umgesetzt werden soll.

### Wie?

1. Erstelle einen neuen Ordner: `docs/product/specs/NNNN-feature-name/`
2. Kopiere die Templates aus `docs/product/specs/_template/`
3. Fülle die Dateien aus

### Beispiel: Ordnerstruktur

```
docs/product/specs/0001-onboarding-kurz/
├── feature.md
├── requirements.md
├── acceptance-criteria.md
├── open-questions.md
├── out-of-scope.md
├── ux.md
├── data-contract.md
└── release-plan.md
```

### Beispiel: feature.md (ausgefüllt)

```markdown
# Feature: Onboarding kürzen

## Metadaten

- **Status:** specified
- **Target release:** next
- **Source:** docs/product/feature-candidates.md
- **Created:** 2026-06-15

## Summary

Das Onboarding wird von 7 Screens auf 3 Screens reduziert.

## Problem

Neue Nutzer brechen das Onboarding ab, weil es zu lang ist.
Nur 40% der Nutzer kommen bis zum Ende.

## Goals

- Onboarding auf maximal 3 Screens reduzieren
- Abschlussrate auf >70% erhöhen
- Alle kritischen Informationen beibehalten

## Non-goals

- Gamification
- A/B-Testing-Framework
- Analytics-Integration (kommt separat)

## Users / Actors

- Neue Nutzer, die die App zum ersten Mal öffnen

## Assumptions

- Die aktuelle Abbruchrate liegt an der Länge, nicht am Inhalt
- 3 Screens sind genug für die nötigsten Informationen
- Optionale Infos können später im App-Menü zugänglich sein
```

### Beispiel: acceptance-criteria.md (ausgefüllt)

```markdown
# Acceptance Criteria: Onboarding kürzen

## Criteria

- [ ] Onboarding besteht aus genau 3 Screens
- [ ] Screen 1: Willkommen + Kernnutzen (max. 2 Sätze)
- [ ] Screen 2: Berechtigungen (Kalender, Notifications)
- [ ] Screen 3: Fertig + CTA zur Hauptansicht
- [ ] "Überspringen"-Button auf jedem Screen sichtbar
- [ ] Bestehende Nutzer sehen das neue Onboarding NICHT erneut
- [ ] Sprache folgt der Gerätesprache (DE/EN)
- [ ] Screens sind auf kleinen Geräten (320dp Breite) ohne Scrolling nutzbar

## Manual verification steps

1. App frisch installieren → Onboarding startet
2. Alle 3 Screens durchgehen → Hauptansicht erreicht
3. App schließen und neu öffnen → Kein Onboarding mehr
4. Sprache auf EN umstellen → Englische Texte prüfen
5. Auf kleinem Gerät (SE-Größe) testen → Kein Overflow
```

### Mit Copilot erstellen

Nutze den Promotion-Prompt aus `docs/delivery/agent-prompts.md` (Abschnitt B)
oder den Skill `.github/skills/promote-idea-to-spec/SKILL.md`.

---

## Architekturprüfung

### Wann?

Nach der Spezifikation, bevor der Implementierungsplan geschrieben wird.

### Was wird geprüft?

- Hat das Feature Auswirkungen auf die Gesamtarchitektur?
- Müssen arc42-Kapitel aktualisiert werden?
- Brauchen wir einen neuen ADR?
- Gibt es Risiken?

### Wie?

**Option A: Manuell**

1. Lies die Feature-Spec
2. Lies relevante arc42-Kapitel (besonders 05, 06, 08)
3. Lies bestehende ADRs
4. Dokumentiere das Ergebnis

**Option B: Mit Agent**

Nutze den Prompt aus `docs/delivery/agent-prompts.md` (Abschnitt D)
oder den Skill `.github/skills/architecture-impact-review/SKILL.md`.

### Beispiel: Ergebnis einer Architekturprüfung

```markdown
## Architekturprüfung: Onboarding kürzen

### Ergebnis: Kein signifikanter Architektur-Impact

**Begründung:**
- Reine UI-Änderung innerhalb des bestehenden Onboarding-Features
- Keine neuen Packages nötig
- Keine Datenmodell-Änderungen
- Keine API-Änderungen
- Bestehende Feature-First-Struktur wird beibehalten

**Betroffene Bereiche:**
- apps/mobile_app/lib/features/onboarding/ (nur hier)

**ADR nötig?** Nein.

**arc42-Update nötig?** Nein.
```

### Beispiel: Wenn Architecture Impact vorhanden

```markdown
## Architekturprüfung: Push-Benachrichtigungen

### Ergebnis: Signifikanter Architektur-Impact

**Betroffene arc42-Kapitel:**
- 05 (Building Block View): Neues Notification-Package
- 06 (Runtime View): Hintergrund-Scheduling
- 08 (Crosscutting Concepts): Berechtigungsmodell

**Benötigte ADRs:**
- ADR-0008: Notification-Strategie (lokal vs. remote, Package-Wahl)

**Risiken:**
- Plattform-spezifisches Verhalten (Android vs. iOS Background Limits)
- Batterie-Optimierung kann Notifications verzögern

**Test-Auswirkungen:**
- Integration-Tests auf echten Geräten nötig
- Emulator-Tests eingeschränkt
```

---

## Implementierungsplan

### Wann?

Wenn die Spec reif ist und die Architekturprüfung abgeschlossen.

### Wo?

```
docs/delivery/implementation-plans/NNNN-feature-name.md
```

### Beispiel

```markdown
# Implementation Plan: Onboarding kürzen

## Metadaten

- **Status:** approved
- **Feature spec:** docs/product/specs/0001-onboarding-kurz/
- **Target release:** next
- **Created:** 2026-06-16

## Scope

- 3 neue Onboarding-Screens erstellen
- Alte 7 Screens entfernen
- Onboarding-State-Logic beibehalten (einmal gesehen = fertig)

## Non-scope

- Analytics
- A/B-Tests
- Animations (können in separater Story kommen)

## Proposed technical approach

1. Bestehende Onboarding-Widgets durch 3 neue ersetzen
2. PageView-Controller beibehalten (nur weniger Pages)
3. SharedPreferences-Flag "onboarding_complete" bleibt gleich
4. Texte in ARB-Dateien (i18n)

## Components affected

- `apps/mobile_app/lib/features/onboarding/` — komplett überarbeitet
- `apps/mobile_app/lib/l10n/` — neue/geänderte Strings

## Tests and validation

- Widget-Tests für jeden der 3 Screens
- Widget-Test für "Überspringen"-Navigation
- Widget-Test für "Nicht erneut anzeigen"-Logik
- Manueller Test auf kleinem Gerät
- Commands: `cd apps/mobile_app && flutter test`

## Story breakdown

| # | Story | Status |
|---|-------|--------|
| 1 | Onboarding-Screens durch 3 neue ersetzen | draft |
| 2 | i18n-Strings für neue Screens | draft |
| 3 | Widget-Tests für neues Onboarding | draft |
```

---

## Stories erstellen

### Was ist eine Story?

Die kleinste sinnvolle Implementierungseinheit. Eine Story = ein kleiner PR.

### Wo?

```
docs/delivery/stories/NNNN-feature-name/story-NNN-slug.md
```

### Beispiel: Vollständige Story

```markdown
# Story: Onboarding-Screens durch 3 neue ersetzen

## Metadaten

- **Status:** ready
- **Feature:** docs/product/specs/0001-onboarding-kurz/
- **Target release:** next
- **Related issue:** —
- **Related PR:** —

## Goal

Die 7 bestehenden Onboarding-Screens durch 3 neue, kürzere Screens ersetzen.

## Context

Die aktuelle Onboarding-Abschlussrate ist zu niedrig (40%).
Die Feature-Spec definiert genau 3 Screens mit klarem Inhalt.

## Scope

- 3 neue Widgets: WelcomeScreen, PermissionsScreen, DoneScreen
- PageView mit 3 Pages statt 7
- "Überspringen"-Button auf jedem Screen
- Bestehende "onboarding_complete"-Logik beibehalten

## Out of scope

- i18n (eigene Story)
- Tests (eigene Story)
- Animationen
- Analytics

## Relevant files

- `apps/mobile_app/lib/features/onboarding/presentation/`
- `apps/mobile_app/lib/features/onboarding/application/`

## Acceptance criteria

- [ ] Onboarding zeigt genau 3 Screens
- [ ] Screen 1: Willkommen + Kernnutzen
- [ ] Screen 2: Berechtigungs-Anfrage
- [ ] Screen 3: Fertig-Meldung + Start-Button
- [ ] "Überspringen"-Button auf jedem Screen
- [ ] Nach Abschluss wird "onboarding_complete" gesetzt
- [ ] Bestehende Nutzer (Flag gesetzt) sehen kein Onboarding

## Test requirements

- Widget-Test: 3 Screens werden gerendert
- Widget-Test: "Überspringen" navigiert zum Ende
- Widget-Test: "onboarding_complete" wird gesetzt
- Commands: `cd apps/mobile_app && flutter test test/features/onboarding/`
- `cd apps/mobile_app && flutter analyze`

## Implementation notes

- Alte Screen-Widgets können gelöscht werden (nicht mehr referenziert)
- PageController.jumpToPage(2) für "Überspringen"
- Texte erstmal hardcoded (i18n kommt in nächster Story)

## Review checklist

- [ ] Genau 3 Screens
- [ ] Keine neuen Dependencies
- [ ] Alte Screens entfernt
- [ ] Tests vorhanden
- [ ] Kein Scope Creep
```

---

## Implementierung (Code schreiben)

### Voraussetzung

- Story hat Status `ready`
- Akzeptanzkriterien sind klar
- Testanforderungen sind definiert

### Ablauf

1. **Vor dem Coden lesen:**
   - AGENTS.md
   - .github/copilot-instructions.md
   - Relevante Feature-Spec
   - Die Story
   - Relevante ADRs

2. **Implementieren:**
   - NUR was in der Story steht
   - Scope NICHT erweitern
   - Bestehende Struktur respektieren

3. **Tests:**
   - Tests schreiben wie in der Story spezifiziert
   - Tests ausführen
   - Ergebnisse dokumentieren

4. **PR erstellen:**
   - PR-Template ausfüllen
   - Story und Spec verlinken
   - Testergebnisse eintragen

### Beispiel: Workflow in der Praxis

```bash
# 1. Story lesen und verstehen
cat docs/delivery/stories/0001-onboarding-kurz/story-001-neue-screens.md

# 2. Code schreiben (in apps/mobile_app/lib/features/onboarding/)
# ...

# 3. Tests schreiben und ausführen
cd apps/mobile_app
flutter analyze
flutter test test/features/onboarding/

# 4. Commit + PR
git add -A
git commit -m "feat(onboarding): replace 7 screens with 3 shorter ones

Implements story-001 from spec 0001-onboarding-kurz.
Acceptance criteria: all met."
```

---

## Pull Request erstellen

### Template ausfüllen

Das PR-Template (`.github/PULL_REQUEST_TEMPLATE.md`) hat diese Abschnitte:

```markdown
## Summary
Onboarding von 7 auf 3 Screens reduziert.

## Why
Abschlussrate zu niedrig (40%). Spec definiert kürzeres Onboarding.

## Related issue / story / spec
- Story: docs/delivery/stories/0001-onboarding-kurz/story-001-neue-screens.md
- Spec: docs/product/specs/0001-onboarding-kurz/

## Scope
- 3 neue Screen-Widgets
- PageView angepasst
- Alte Screens entfernt

## Out of scope confirmation
- Keine i18n (separate Story)
- Keine Animationen
- Keine Analytics

## Tests executed
- `flutter analyze` — 0 issues
- `flutter test test/features/onboarding/` — 3 tests passed

## Tests not executed and reason
- Integration-Test auf echtem Gerät: Kein physisches Gerät in CI verfügbar.
  Manuell auf Pixel 7 getestet.
```

---

## Review

### Worauf achten?

1. **Scope:** Passt der PR zur Story?
2. **Akzeptanzkriterien:** Alle erfüllt?
3. **Tests:** Vorhanden? Sinnvoll? Dokumentiert?
4. **Dependencies:** Neue Packages ohne Begründung?
5. **Architektur:** Unerwartete Strukturänderungen?
6. **Dokumentation:** Updates nötig?

### Copilot Code Review nutzen

Copilot Code Review kann als erste Prüfschicht dienen.
Es ersetzt NICHT die menschliche Review.

### Review-Prompt für Agenten

Siehe `docs/delivery/agent-prompts.md` (Abschnitt H)
oder Skill `.github/skills/review-copilot-pr/SKILL.md`.

---

## Nach der Umsetzung

1. Story-Status auf `implemented` setzen
2. Feature-Spec-Status aktualisieren (wenn alle Stories fertig)
3. Roadmap aktualisieren
4. Optional: Review-Protokoll unter `docs/delivery/reviews/` anlegen

---

## Skills und Agents nutzen

### Verfügbare Workflow-Skills

| Skill | Zweck | Ändert Code? |
|-------|-------|:---:|
| `simple-idea-triage` | Neue Ideen sortieren | Nein |
| `promote-idea-to-spec` | Kandidat → Spec | Nein |
| `architecture-impact-review` | Architekturprüfung | Nein |
| `create-implementation-plan` | Plan aus Spec | Nein |
| `split-plan-into-stories` | Plan → Stories | Nein |
| `implement-approved-story` | Story umsetzen | **Ja** |
| `review-copilot-pr` | PR prüfen | Nein |

Skills liegen unter `.github/skills/<name>/SKILL.md`.

### Agents

| Agent | Rolle |
|-------|-------|
| `planner.agent.md` | Analysiert, plant, zerlegt in Schritte |
| `implementer.agent.md` | Setzt Code um, hält sich an Struktur |
| `reviewer.agent.md` | Prüft Architektur, Tests, Hygiene |

Agents liegen unter `.github/agents/`.

---

## Copilot Coding Agent beauftragen

### Schritt-für-Schritt

1. **Story muss existieren** mit Status `ready`
2. **GitHub Issue erstellen** mit Template "Copilot Task"
3. **Issue ausfüllen:**
   - Goal, Context, Story-File, Relevant Files
   - Acceptance Criteria, Out of Scope
   - Tests Required, Test Commands
   - Forbidden Changes
4. **Copilot Coding Agent zuweisen** (Label `copilot-task` oder direkt)

### Beispiel: Copilot-Task-Issue

```yaml
Goal: Ersetze die 7 Onboarding-Screens durch 3 neue kurze Screens

Context: |
  Feature-Spec: docs/product/specs/0001-onboarding-kurz/
  Die Abschlussrate ist zu niedrig. Spec definiert genau 3 Screens.

Story file: docs/delivery/stories/0001-onboarding-kurz/story-001-neue-screens.md

Relevant files: |
  - apps/mobile_app/lib/features/onboarding/presentation/
  - apps/mobile_app/lib/features/onboarding/application/
  - apps/mobile_app/test/features/onboarding/

Acceptance criteria: |
  - Onboarding zeigt genau 3 Screens
  - "Überspringen"-Button auf jedem Screen
  - "onboarding_complete"-Flag wird gesetzt
  - Bestehende Nutzer sehen kein erneutes Onboarding

Out of scope: |
  - i18n (separate Story)
  - Animationen
  - Analytics
  - Andere Features

Tests required: |
  - Widget-Tests für alle 3 Screens
  - Test für "Überspringen"-Navigation
  - Test für Flag-Logik
  - Commands: flutter test, flutter analyze

Forbidden changes: |
  - packages/ (kein Grund für Änderungen dort)
  - services/ (Backend nicht betroffen)
  - .github/workflows/ (CI nicht ändern)
  - docs/architecture/ (kein Architektur-Impact)

Expected PR summary: |
  feat(onboarding): reduce onboarding from 7 to 3 screens
  - Added WelcomeScreen, PermissionsScreen, DoneScreen
  - Removed old onboarding screens
  - Added widget tests
```

---

## Häufige Fehler vermeiden

| Fehler | Richtig |
|--------|---------|
| Direkt aus Idee coden | Erst triagieren → Kandidat → Spec → Story |
| Riesiger PR mit 20 Dateien | Eine Story = ein kleiner PR |
| Tests vergessen | Jede Story hat Testanforderungen |
| Scope erweitert | Nur das umsetzen, was in der Story steht |
| Neue Dependency ohne Grund | Begründen, idealerweise ADR |
| arc42 als Backlog nutzen | arc42 = Architektur-Doku, nicht Ideen |
| Rohideen markieren | Status in processed-index.yml, nicht in ideas.md |
| Bestehende Struktur umbauen | Erweitern ja, ersetzen nein |

---

## Schnellreferenz: Dateipfade

| Was | Wo |
|-----|-----|
| Rohideen | `docs/ideas/simple/ideas.md` |
| Verarbeitungsstatus | `docs/ideas/simple/processed-index.yml` |
| Triage-Ergebnisse | `docs/ideas/triage/idea-triage.md` |
| Feature-Kandidaten | `docs/product/feature-candidates.md` |
| Roadmap | `docs/product/roadmap.md` |
| Feature-Specs | `docs/product/specs/<NNNN-name>/` |
| Spec-Templates | `docs/product/specs/_template/` |
| Implementierungspläne | `docs/delivery/implementation-plans/` |
| Stories | `docs/delivery/stories/<NNNN-name>/` |
| Reviews | `docs/delivery/reviews/` |
| Agent-Prompts | `docs/delivery/agent-prompts.md` |
| arc42 | `docs/architecture/arc42/` |
| ADRs | `docs/architecture/adr/` |
| Skills | `.github/skills/` |
| Agents | `.github/agents/` |
| Issue-Templates | `.github/ISSUE_TEMPLATE/` |
| PR-Template | `.github/PULL_REQUEST_TEMPLATE.md` |
| Copilot-Instructions | `.github/copilot-instructions.md` |
| Agent-Instructions | `AGENTS.md` |

---

## Komplettes Beispiel: Von der Idee zum PR

### 1. Idee aufschreiben

```markdown
### 2026-06-20

- [v1] Export: Nutzer sollen ihre Termine als JSON exportieren können
```

### 2. Triage

→ Feature-Kandidat: "Termin-Export als JSON"
→ Roadmap: v1
→ processed-index.yml aktualisiert

### 3. Feature-Kandidat bewerten

→ User Value: hoch (Datensouveränität)
→ Architecture Impact: mittel (neues Export-Modul)
→ Recommendation: Spec schreiben

### 4. Spec erstellen

```
docs/product/specs/0002-termin-export/
├── feature.md          → Ziele, Nicht-Ziele, Annahmen
├── requirements.md     → JSON-Format, Versionierung
├── acceptance-criteria.md → Testbare Kriterien
├── open-questions.md   → Verschlüsselung nötig? Maximalgröße?
├── out-of-scope.md     → Kein Import, kein Cloud-Sync
├── data-contract.md    → JSON-Schema, version-Feld
└── release-plan.md     → v1, Phase 1: nur JSON
```

### 5. Architekturprüfung

→ Neues Package? Nein, `packages/shared_models` reicht.
→ ADR nötig? Ja → ADR-0008: Export-Format (JSON + version field)
→ arc42-Update? Ja → 05 (neuer Building Block: ExportService)

### 6. Implementierungsplan

```
docs/delivery/implementation-plans/0002-termin-export.md
```
→ 3 Stories identifiziert

### 7. Stories erstellen

```
docs/delivery/stories/0002-termin-export/
├── story-001-define-export-format.md
├── story-002-implement-export-service.md
└── story-003-add-export-button-ui.md
```

### 8. Story 001 implementieren

- Status auf `ready` setzen
- Copilot-Task-Issue erstellen (oder manuell coden)
- Tests schreiben und ausführen
- PR erstellen

### 9. Review + Merge

- Story-Status: `implemented`
- Nächste Story: story-002
- Wenn alle Stories fertig: Spec-Status `implemented`

---

> Diese Anleitung ist selbst Dokumentation, kein Code.
> Sie kann jederzeit ergänzt oder angepasst werden.
