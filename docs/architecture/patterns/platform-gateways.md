# Platform Gateways

Wie Plugins und riskante Abhängigkeiten aus dem Rest der App herausgehalten
werden. Regel dazu: [Library Evaluation Contract](../contracts/06-library-evaluation.md),
Punkt 8. Erzwungen wird sie durch einen Test, nicht durch Reviews.

## Drei Stufen — die passende auswählen

Nicht jede Abhängigkeit braucht dieselbe Ummantelung. Zu viel Kapselung ist
Ballast, zu wenig kostet beim ersten Paketwechsel.

### 1. Typedef-Seam — für Ein-Aufruf-Plugins

Wenn das Plugin genau eine Operation ohne Zustand ausführt (Link öffnen,
Text teilen, in die Zwischenablage schreiben), ist eine Funktionssignatur
die ganze Schnittstelle:

```dart
// lib/core/platform/platform_seams.dart
typedef LaunchUrl = Future<bool> Function(Uri uri);

@Riverpod(keepAlive: true)
LaunchUrl urlLauncher(Ref ref) => (uri) => url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
```

Im Test:

```dart
urlLauncherProvider.overrideWithValue((uri) async {
  launched.add(uri);
  return true;
}),
```

Zwei Zeilen Produktionscode kaufen vollständige Testbarkeit — das ist das
beste Verhältnis im ganzen Katalog. **Das Template nutzt diese Stufe für
`url_launcher`, `share_plus`, `Clipboard`, `package_info_plus` und
`device_info_plus`.**

### 2. Gateway-Interface — für Fähigkeiten mit Verhalten

Sobald mehrere Operationen zusammengehören, Zustand im Spiel ist oder
Sicherheitsregeln gelten (Berechtigungen, Schreibzugriffe auf fremde
Systeme), reicht ein Typedef nicht mehr:

```dart
// domain/ — reines Dart, kein Plugin-Typ
enum PermissionState { notRequested, granted, denied, permanentlyDenied }

/// Read-only access to the device address book.
///
/// Deliberately exposes NO write operation: contacts are external source
/// data, the app never modifies them. What the app must not do is not
/// expressible here — that is stronger than any comment.
abstract interface class ContactGateway {
  Future<PermissionState> status();
  Future<PermissionState> request();
  Future<List<ExternalContact>> load();
}
```

```dart
// data/ — die einzige Datei, die das Plugin importiert
class FlutterContactsGateway implements ContactGateway { ... }

// data/ — Provider
@Riverpod(keepAlive: true)
ContactGateway contactGateway(Ref ref) => FlutterContactsGateway();
```

**Das Interface ist der eigentliche Gewinn**, nicht die Austauschbarkeit:
Was die App nicht darf, steht gar nicht erst im Vertrag.

#### Der Fake gehört dazu — und prüft die Regeln mit

Ein Fake, der nur Werte zurückgibt, ist eine verpasste Gelegenheit. Er ist
die einzige Stelle, an der eine Sicherheitsinvariante bei **jedem** Testlauf
geprüft wird:

```dart
class FakeCalendarGateway implements CalendarGateway {
  final appCreatedIds = <String>{};

  @override
  Future<void> deleteEvent(String calendarId, String eventId) async {
    if (!appCreatedIds.contains(eventId)) {
      // Not an assertion about this test — an assertion about the app.
      throw StateError('SAFETY VIOLATION: delete of non-app event $eventId');
    }
    ...
  }
}
```

Dazu ein „fremder" Eintrag, den der Fake anlegt und der **jeden** Lauf
überleben muss. Ein generierter Mock kann das nicht.

### 3. Adapter mit eigenen Grenztypen — für UI-Pakete und Pre-1.0

Wenn ein Paket eigene Modelltypen in die App drücken würde (Kalenderansicht,
Diagramm, Editor), kommt ein app-eigener Grenztyp dazwischen:

```
Domäne → Mapper → AppDisplayEvent → Adapter → Paket
```

Das Paket sieht nie einen Domänentyp, die App speichert nie einen Pakettyp.
Ein Wechsel betrifft Adapter und Mapper — zwei Dateien.

## Der Guardrail-Test

Die Architekturregel allein erodiert: ein „schneller" Import außerhalb des
Adapters fällt im Review nicht auf, und wenn das Paket ersetzt werden soll,
steht es in dreißig Dateien. Deshalb wird sie getestet:

```dart
// test/features/splash/lottie_encapsulation_test.dart
import '../../support/package_encapsulation.dart';

void main() {
  expectPackageEncapsulated(
    package: 'lottie',
    allowedDirectory: 'lib/features/splash/presentation',
  );
}
```

Der Helfer scannt `lib/` und schlägt mit der Liste der Fundstellen fehl.
`test/support/package_encapsulation.dart` bietet zusätzlich
`findPackageImportsOutside(...)` für eigene Zusicherungen.

## Wann **nicht** kapseln

| Art | Wrapper? |
|---|---|
| Plattformoperation (Kontakte, Kalender, Kamera, Billing, Dateien) | ja — Gateway-Interface |
| Ein-Aufruf-Plugin (Launcher, Share, Clipboard, Geräteinfo) | ja — Typedef-Seam |
| UI-Paket, Pre-1.0 oder mit hoher API-Drift | ja — Adapter + Kapselungstest |
| Compile-Time-Generator (Freezed, json_serializable, riverpod_generator) | nein |
| Reine Dart-Utility (`intl`, `collection`) | nein |

Faustregel: **Kapseln, wenn das Paket eine Plattformoperation ausführt, ein
Lizenz- oder Wartungsrisiko trägt oder schwer zu fälschen ist. Nicht kapseln,
was zur Compile-Zeit verschwindet oder reines Dart ist.**

## Auch die Zeit ist eine Plattformabhängigkeit

`DateTime.now()` ist der am häufigsten übersehene Seam. Code, der die echte
Uhr liest, ist konstruktionsbedingt flaky — er ändert sein Verhalten um
Mitternacht, an Monatsenden, am 29. Februar und bei Zeitumstellungen.

```dart
// lib/core/utils/clock.dart
abstract interface class Clock {
  DateTime now();
}

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();
```

Im Test `clockProvider.overrideWithValue(FixedClock(...))` — der Test-Harness
tut das bereits standardmäßig.
