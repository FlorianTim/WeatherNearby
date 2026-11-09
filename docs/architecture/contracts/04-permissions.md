# Permission Contract

Gilt, sobald eine App eine Laufzeitberechtigung anfordert.

## Ablauf

```
Feature-Aktion des Nutzers
        ↓
Statusabfrage am System
        ↓
In-App-Rationale (was, wofür, was passiert bei Nein)
        ↓
Nutzer bestätigt
        ↓
System-Dialog
        ↓
granted / denied / permanentlyDenied
        ↓
Feature aktiv  |  eingeschränkter Modus  |  Weg in die Systemeinstellungen
```

## Regeln

1. **Keine pauschalen Berechtigungen beim App-Start.** Splash und Router
   fassen keine Berechtigungs-API an. Auch keine Verfügbarkeitsabfrage, die
   einen Dialog auslösen könnte.
2. **Vor jedem System-Dialog steht eine In-App-Rationale**, die folgenlos
   abgelehnt werden kann.
3. **Die Anfrage erfolgt bei der tatsächlichen Feature-Nutzung**, nicht beim
   Betreten eines Screens.
4. **Ein abgelehnter Zustand lässt die App benutzbar.** Das betroffene
   Feature degradiert und benennt, was dadurch fehlt.
5. **`permanentlyDenied` ist ein eigener Zustand** und führt zu einem Weg in
   die Systemeinstellungen. Er darf nicht mit `denied` verschmolzen werden —
   sonst gibt es für den Nutzer keinen Rückweg.
6. **Das System bleibt die Quelle der Wahrheit.** Der Status wird abgefragt,
   nicht aus einem Cache abgeleitet; ein gespeicherter Wert ist höchstens
   ein Anzeigehinweis. Eine in den Systemeinstellungen entzogene
   Berechtigung muss beim nächsten Lesen auffallen, nicht erst beim nächsten
   Schreiben.
7. **Die Manifest-Einträge listen nur tatsächlich genutzte Berechtigungen.**
   Was die App nicht braucht, steht nicht im Manifest — das ist die
   wirksamste Zusicherung, die es gibt.
8. **Tests laufen gegen ein Fake-Gateway** und decken
   `notRequested` / `granted` / `denied` / `permanentlyDenied` ab, inklusive
   des degradierten Pfads — nicht nur des glücklichen.

## Generische Form

```dart
enum PermissionState { notRequested, granted, denied, permanentlyDenied }

abstract interface class PermissionGateway {
  Future<PermissionState> status();      // muss auch wirklich aufgerufen werden
  Future<PermissionState> request();     // nur nach der Rationale
  Future<void> openAppSettings();        // für permanentlyDenied
}
```

Dieselbe Form trägt `contacts`, `calendar`, `notifications`, `location`,
`photos/media`, `camera` und `microphone`. Unterschiedlich sind nur der Text
der Rationale und das Plugin hinter dem Gateway — nicht die Architektur.

## Stand im Template

| Regel | Stand |
|---|---|
| 1 | ✅ Startup fasst keine Berechtigungs-API an |
| 2 | ✅ `showPermissionRationale(...)` in `lib/core/permissions/` |
| 3 | ✅ `ensurePermission(...)` wird aus der Feature-Aktion gerufen — dokumentiert in [permissions.md](../patterns/permissions.md) |
| 4 | ✅ Der Ablauf liefert den Zustand zurück, statt zu werfen; der Aufrufer degradiert |
| 5 | ✅ `permanentlyDenied` ist ein eigener Zustand mit Weg in die Systemeinstellungen |
| 6 | ✅ `status()` fragt das System; das Template cacht nichts |
| 7 | ✅ `test/support/fake_permission_gateway.dart` mit Aufrufprotokoll, 10 Tests |
| 8 | ✅ Das Template fordert keine Berechtigung an, also steht keine im Manifest |

Seit 3.2.1 zeigt die Datenschutz-Seite (`lib/features/privacy/`) eine
Übersicht der gehaltenen Berechtigungen mit ihrem aktuellen Zustand. Sie
fragt **nicht** selbst ab, sondern rendert, was die App ihr übergibt — eine
Liste von `PermissionOverviewEntry`. Im Template ist die Liste leer, und der
Abschnitt entfällt dann vollständig (Spezifikation 0005, SET-032). Eine
abgeleitete App füllt sie aus ihren eigenen Gateways; die Seite bleibt
dadurch frei von jeder Plugin-Abhängigkeit.

Was **nicht** im Template liegt: die konkrete Implementierung je Berechtigung.
Sie bringt ein Plugin, Manifest-Einträge und Store-Fragen mit und ist damit
eine App-Entscheidung — Rezept in
[patterns/permissions.md](../patterns/permissions.md).
