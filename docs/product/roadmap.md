# Roadmap

> Roadmap entries are directional, not implementation approvals.
> Code is only changed from approved stories or explicit Copilot task issues.

## Now

- Repo-Struktur aufsetzen
- erstes End-to-End-Feature bauen
- App-Konfiguration für dev/staging/prod festziehen
- **3.1.0 — To-do-Referenz-App** (ersetzt die Todo-Demo).
  Die Beispiel-App wird vom Smoke-Test zum Prüfstand: genug Oberfläche, um
  bei einem Flutter-Release, einem Drift-Major oder einem neuen Standard
  tatsächlich zu brechen — bevor eine produktive App abgeleitet wird.
  Entscheidung: ADR-0011. Spezifikationen: `docs/product/specs/0001` bis
  `0004`. Plan: `docs/delivery/implementation-plans/0001-todo-reference-app.md`.
- **3.2.1 — App-Shell (umgesetzt).** Einstellungen als Hub, Anleitung und
  häufige Fragen in der App, Datenschutz-Seite mit beiden zerstörenden
  Aktionen, App-Einleitung beim ersten Start, In-App-Kauf-Platzhalter ohne
  Billing-Abhängigkeit. Entscheidung: ADR-0015. Spezifikationen:
  `docs/product/specs/0005` bis `0007`. Plan:
  `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`.

## Next

- **Backup und Wiederherstellung.** In `0001-todo-reference-app.md` als
  3.2+-Kandidat benannt und in Spezifikation 0005 bewusst ausgeklammert: ein
  Dateiformat ist ein Kompatibilitätsversprechen und braucht eine eigene
  Spezifikation.
- **Echte In-App-Käufe.** Der Seam steht (ADR-0015), das Rezept liegt unter
  `docs/architecture/patterns/in-app-purchase-gateway.md`. Was fehlt, ist
  eine Produktentscheidung, kein Template-Baustein.
- Authentifizierung
- API-Kontrakte konkretisieren
- Store-Release-Pipeline härten

## v1

_(no v1-specific items yet)_

## v2

_(no v2-specific items yet)_

## v3

_(no v3-specific items yet)_

## Later

- Telemetrie / Analytics
- Feature Flags
- Admin- oder Backoffice-Themen

## Someday

_(no someday items yet)_

## Rejected / Archived

_(none)
