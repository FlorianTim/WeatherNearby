# External Data Ownership Contract

Gilt, sobald eine App Daten aus einer fremden Quelle liest (Kontakte,
Kalender, Dateien, Sensoren, später APIs) **oder** in ein System schreibt,
das sie sich mit dem Nutzer teilt.

> **Leitsatz:** `Fremddaten ≠ eigene Daten.` Importierte Daten dürfen
> aussehen wie eigene, aber ihr Lebenszyklus gehört der Quelle.

## Lesen: die Kette

```
Externe Quelle
      ↓        Gateway (nur lesende Operationen)
Gateway
      ↓        DTO mit Fingerprint
Importierte Repräsentation
      ↓        Link-Zeile (provider, externalId, fingerprint, sourceMissing)
Stabile lokale Identität   ← app-generierte ID, NIE die externe
      ↓
App-eigene Erweiterungen   ← Notizen, Flags, Verknüpfungen
```

## Regeln

1. **Externe und eigene Daten sind jederzeit unterscheidbar** — getrennte
   Tabellen, ein `origin`/`provider`-Diskriminator und eine Link-Zeile.
2. **Jedes importierte Element bekommt eine stabile lokale Identität**, die
   die App erzeugt. Die externe ID ist ein Attribut, nie ein
   Primärschlüssel — mit `UNIQUE(provider, external_id)` auf der Link-Zeile.
3. **Änderungen an der Quelle werden erkannt** über einen Fingerprint oder
   Content-Hash, der in der Domänenschicht berechnet wird.
4. **Die Quelle darf verschwinden, ohne lokale Daten zu zerstören.**
   Nicht mehr gefunden → `sourceMissing = true`. **Niemals automatisch
   löschen.**
5. **Lokale Änderungen gewinnen dort, wo der Nutzer bewusst überschrieben
   hat** — ausgedrückt durch ein explizites Flag pro Feld, nicht durch
   Heuristik.
6. **Synchronisation ist idempotent.** Ein erneuter Lauf ohne Änderung an
   der Quelle schreibt nichts. Der gesamte Abgleich läuft in einer
   Transaktion.

## Schreiben: „Write only what you own"

7. **Nur in einen selbst angelegten Container schreiben** und dessen
   Zugehörigkeit vor jedem Zugriff verifizieren (Name **und** Konto/Owner,
   nicht nur der Name).
8. **Nur eigene Elemente ändern oder löschen** — positiv identifiziert über
   die Ownership-Zuordnung `(logischer Schlüssel) → (Container, Provider-ID,
   Content-Hash, Status)` **oder** über einen versionierten Marker im Inhalt,
   falls die Zuordnung verloren geht.
9. **Niemals fremde Daten auf Verdacht löschen.** Was weder zugeordnet ist
   noch den Marker trägt, bleibt unangetastet.
10. **Vom Nutzer gelöschte eigene Elemente werden respektiert** — als
    `user_removed` markiert und nie automatisch neu erzeugt. Rückgängig nur
    über eine explizite Regenerierung.
11. **Das Gateway kann Unsicheres nicht ausdrücken.** Was die App nicht darf,
    steht nicht im Interface — eine reine Lesequelle bekommt keine
    Schreiboperation.
12. **Der Test-Fake erzwingt die Regeln.** Er wirft bei jedem Zugriff auf ein
    nicht eigenes Element und enthält ein „fremdes" Element, das jeden Lauf
    überleben muss.

## Sync-Pipeline

```
Read source → Normalize (DTO + Fingerprint) → Compare (Hash)
→ Plan (create/update/delete/skip) → Execute (Fehler pro Element isoliert)
→ Persist mapping/status → Report
```

- Ein Fehler an einem Element bricht den Lauf nicht ab.
- Ein **übersprungener** Lauf wird ebenfalls protokolliert — der Nutzer muss
  sehen, *warum* nichts passiert ist.
- Gründe sind Enums mit stabilem Persistenzwert, erst bei der Anzeige
  lokalisiert. Nie eine Exception-Nachricht, nie ein Stacktrace.
- Berichte duplizieren keine personenbezogenen Daten: technische Schlüssel
  speichern, Titel beim Anzeigen aus den Livedaten rendern.
- Bei einer Vervielfachung (n Quellen × m Perioden) wird die **Rechnung**
  gespeichert und angezeigt, nicht nur die Gesamtzahl — sonst liest sich ein
  korrektes Ergebnis wie ein Duplikatsfehler.

## Stand im Template

Kein Modul vorhanden (`❌`) — External Source, Ownership-Mapping und
Sync-Protokoll kosten mindestens eine zusätzliche Tabelle (also einen
`schemaVersion`-Bump) plus das Plugin der jeweiligen Quelle. Sie sind damit
Capabilities, keine Baseline.

Das vollständige Rezept mit Tabellenzuschnitt, Abgleichregeln,
Ownership-Marker und Protokollaufbau liegt unter
[patterns/external-source-sync.md](../patterns/external-source-sync.md).

Was das Template seit 3.2.1 **hat**, ist die Aussage dazu in der App selbst:
die Datenschutz-Seite (`lib/features/privacy/`) benennt in der App-Sprache,
dass alles lokal gespeichert wird, listet die veröffentlichten Dokumente und
besitzt die beiden zerstörenden Aktionen — Inhalte löschen und Einstellungen
zurücksetzen, jede mit eigener Bestätigung und eigenem Wirkungsbereich. Diese
Zusage darf eine App nur machen, solange kein Sync-Modul dazukommt; wer eines
ergänzt, muss den Text der Seite mitziehen.
