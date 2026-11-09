# Permissions

Das Zustandsmodell und der Ablauf liegen als Code im Template
(`lib/core/permissions/`). Was fehlt, ist pro Berechtigung genau eine
Implementierung des Gateways — dieses Rezept beschreibt sie.

Regeln: [Permission Contract](../contracts/04-permissions.md).

## Was das Template mitbringt

| Datei | Inhalt |
|---|---|
| `permission_gateway.dart` | `PermissionState` (4 Zustände) und `PermissionGateway` |
| `permission_flow.dart` | `ensurePermission(...)` — der gesamte Ablauf |
| `permission_rationale_sheet.dart` | `PermissionCopy` und die beiden Sheets |
| `test/support/fake_permission_gateway.dart` | Fake mit Aufrufprotokoll |

`ensurePermission` ist der Grund, warum es das Modul gibt: die Reihenfolge

```
status() → (granted? fertig) → (permanentlyDenied? Settings-Weg)
         → In-App-Rationale → (abgelehnt? fertig) → request()
```

ist der Teil, den Apps falsch machen — und der Fehler fällt erst auf, wenn
ein Nutzer feststeckt.

## Eine Berechtigung anbinden

### 1. Gateway implementieren

```dart
// lib/features/<feature>/data/calendar_permission_gateway.dart
class CalendarPermissionGateway implements PermissionGateway {
  @override
  Future<PermissionState> status() async {
    // MUSS das System fragen. Ein gecachter Wert ist nach einem Entzug in
    // den Systemeinstellungen falsch — und zwar still.
    final status = await Permission.calendarFullAccess.status;
    return _map(status);
  }

  @override
  Future<PermissionState> request() async =>
      _map(await Permission.calendarFullAccess.request());

  @override
  Future<void> openAppSettings() => permission_handler.openAppSettings();

  PermissionState _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => PermissionState.granted,
    // iOS 18 „limited" erlaubt weiterhin das Lesen der freigegebenen
    // Einträge — als granted behandeln, sonst wirkt die App kaputt.
    PermissionStatus.limited => PermissionState.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => PermissionState.permanentlyDenied,
    _ => PermissionState.denied,
  };
}
```

> **Die Zuordnung ist die eigentliche Arbeit.** `permanentlyDenied` in
> `denied` zu falten ist der häufigste Fehler und nimmt dem Nutzer den
> Rückweg. `restricted` (Geräterichtlinie, Kindersicherung) verhält sich
> genauso: es wird kein Dialog mehr erscheinen.

**Paketwahl:** `permission_handler` deckt alle Berechtigungen plus
`openAppSettings()` ab. Manche Plugins bringen ihre eigene Abfrage mit
(`flutter_contacts`, `device_calendar`) — dann braucht es das zusätzliche
Paket nur noch für den Weg in die Systemeinstellungen. Beides ist eine
Entscheidung nach dem
[Library Evaluation Contract](../contracts/06-library-evaluation.md).

### 2. Provider bereitstellen

```dart
@Riverpod(keepAlive: true)
PermissionGateway calendarPermission(Ref ref) => CalendarPermissionGateway();
```

### 3. Texte formulieren

```dart
PermissionCopy calendarCopy(AppLocalizations l10n) => PermissionCopy(
  title: l10n.calendarPermissionTitle,
  rationale: l10n.calendarPermissionRationale,
  icon: Icons.calendar_month,
  blockedHint: l10n.calendarPermissionBlocked,
);
```

Die Rationale nennt **beides**: wofür die Berechtigung gebraucht wird und
was ohne sie fehlt. „Diese App benötigt Zugriff auf deinen Kalender" ist
genau der Satz, den Nutzer ablehnen.

### 4. Aus der Feature-Aktion aufrufen

```dart
Future<void> _enableSync(BuildContext context, WidgetRef ref) async {
  final state = await ensurePermission(
    context: context,
    gateway: ref.read(calendarPermissionProvider),
    copy: calendarCopy(AppLocalizations.of(context)),
  );

  if (!state.isGranted) {
    // Kein Fehler: die App bleibt benutzbar und benennt, was fehlt.
    _showLimitedModeHint();
    return;
  }
  await ref.read(syncServiceProvider).run();
}
```

Nicht in `initState`, nicht beim App-Start, nicht beim Betreten des Screens
— erst bei der Aktion, die die Berechtigung tatsächlich braucht.

### 5. Manifest ergänzen — nur das Genutzte

```xml
<!-- Nur lesen. Kein WRITE_CALENDAR, solange die App nicht schreibt. -->
<uses-permission android:name="android.permission.READ_CALENDAR" />
```

Was nicht im Manifest steht, kann die App nicht anfordern. Das ist die
belastbarste Zusicherung, die es gibt — stärker als jede Formulierung in
der Datenschutzerklärung.

### 6. Testen — beide Pfade

```dart
final gateway = FakePermissionGateway(
  state: PermissionState.permanentlyDenied,
);

await tester.tap(find.text('Synchronisierung aktivieren'));
await tester.pumpAndSettle();

expect(gateway.requestCount, 0);          // kein Dialog, der nie erscheint
expect(find.text('Nur in der App sichtbar'), findsOneWidget);
```

Der abgelehnte Pfad ist der wichtigere Test: der glückliche fällt beim
ersten manuellen Durchlauf auf, der andere nicht.

## Degradation je Berechtigung

Die Frage „was kann die App ohne diese Berechtigung noch?" gehört
beantwortet, **bevor** sie angefordert wird:

| Berechtigung | Ohne sie |
|---|---|
| Kontakte | manuell angelegte Einträge funktionieren weiter |
| Kalender | Termine bleiben in der App sichtbar, kein Export |
| Benachrichtigungen | Fälliges erscheint weiter in der App-Liste |
| Standort | manuelle Auswahl statt automatischer Erkennung |
| Kamera / Fotos | Auswahl aus vorhandenen Dateien |

Wenn die Antwort „dann geht gar nichts" lautet, ist meist der Schnitt des
Features falsch, nicht die Berechtigung.
