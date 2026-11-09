# Startup Contract

Gilt für jede App aus diesem Template.

## Phasen

```
Android-System-Splash (API 31+, nicht abschaltbar)
        ↓        bzw. Launch-Window (< API 31)
Flutter-Engine startet
        ↓
Phase 1: LumbreCode-Reveal
        ↓
Phase 2: App-Reveal
        ↓
Initialisierung abgeschlossen
        ↓
Onboarding / Setup / Hauptnavigation
```

## Regeln

1. **Der native Splash zeigt Markenbranding, nie Flutter-Standard.**
   Ab API 31 über `windowSplashScreenBackground` und
   `windowSplashScreenAnimatedIcon` in `values-v31/styles.xml` **und**
   `values-night-v31/styles.xml`. Darunter über
   `LaunchTheme.windowBackground`.
   ⚠️ Ohne `values-night-v31` gewinnt im Dunkelmodus das `values-night`-Theme
   und die Splash-Attribute fallen ersatzlos weg.
2. **Flutter übernimmt ohne ungebrandeten Zwischenframe.** System-Splash,
   `NormalTheme.windowBackground` und der Hintergrund des ersten
   Flutter-`Scaffold` verwenden **dieselbe Farbkonstante**.
3. **Die Firmenphase wird gezeigt** — lokales Asset, niemals von einer URL.
4. **Die App-Phase wird gezeigt** — pro App austauschbares Asset, mit
   Fallback, falls das Asset nicht lädt.
   Beide Phasen laufen **bildschirmfüllend**: Firmen- und App-Name sind Teil
   der Lottie-Datei, der Screen zeichnet keinen eigenen Titel daneben. Die
   Animation wird mit `BoxFit.contain` skaliert — `cover` würde den Namen auf
   abweichenden Seitenverhältnissen anschneiden — und der Letterbox-Rand
   trägt dieselbe Farbe wie die Hintergrundebene der Datei. Für Screenreader
   liefert jede Phase den Namen als `Semantics`-Label; der Fallback zeichnet
   ihn zusätzlich als Text.
5. **Während der Phasen läuft sinnvolle Initialisierung.** Aufgaben
   registrieren sich (`splashWarmupTasksProvider`), statt im Router
   hartkodiert zu sein. Jede Aufgabe fängt ihre eigenen Fehler ab — ein
   fehlgeschlagenes Warmup darf den Start nie blockieren.
6. **Keine künstliche Blockade ohne UX-Grund.** Eine Marken-Mindestdauer ist
   zulässig und muss injizierbar sein; Tests setzen sie nahe null.
7. **Datenbankmigrationen sind vor jedem abhängigen Read abgeschlossen.**
   Strukturell sichergestellt, wenn die Migration im Verbindungsaufbau läuft
   und jeder Read über denselben Provider geht.
8. **Settings, Locale und Theme laden früh** — vor dem ersten Frame, der von
   ihnen abhängt.
9. **Nicht kritische Daten laden lazy.** Nur der erste sichtbare Screen und
   die Routing-Entscheidung dürfen blockieren.
10. **Fehler führen in einen definierten Zustand.** Behebbar → degradieren
    und weiterlaufen. Nicht behebbar (z. B. Datenbank nicht zu öffnen) →
    ein eigener, lokalisierter Recovery-Screen mit einer nächsten Aktion.
    Kein stiller Absturz im Splash.
11. **Der Start ist automatisiert testbar:** injizierbare Zeiten,
    injizierbare Initialisierung, ein Splash-Widget-Test und ein
    End-to-End-Test Splash → erster Screen.

## Phasenordnung

| Phase | Inhalt | Blockierend? |
|---|---|---|
| 0 | Binding, Fehlererfassung | ja |
| 1 | Datenbank öffnen + Migration | ja |
| 2 | Settings, Locale, Theme | ja (lokal, schnell) |
| 3 | Setup-/Onboarding-Zustand → Startroute | ja |
| 4 | Caches für den ersten Screen | nein, gekapselt, parallel |
| 5 | Hintergrundabgleich / Sync | nein, fire-and-forget |

Phasen 0–3 sind vor der Navigation fertig; Phase 4 verzögert sie nicht über
die Marken-Mindestdauer hinaus; Phase 5 blockiert nie.

## Stand im Template

| Regel | Stand |
|---|---|
| 1, 2 | ✅ `scripts/bootstrap/android-res/` wird von `bootstrap_android.*` einkopiert — inkl. `values-night-v31` und `drawable-v21` (siehe [KI-010](../../known-issues.md#ki-010)) |
| 3, 4 | ✅ `lib/features/splash/presentation/splash_page.dart` — Vollbild, Namen aus der Lottie-Datei, Test `draws the animation fullscreen and no title of its own` |
| 5 | ✅ `lib/core/startup/` — `StartupCoordinator` mit Task-Registry |
| 6 | ✅ `splash_timing.dart` + Override im Test-Harness |
| 7 | ✅ Migration läuft in `AppDatabase` beim Verbindungsaufbau |
| 8 | ✅ Locale und Theme werden aus dem `KeyValueStore` gelesen, bevor `MaterialApp` baut |
| 9 | ✅ |
| 10 | ✅ `guarded`/`fireAndForget` degradieren; ein `blocking`-Fehler führt auf `lib/features/splash/presentation/startup_error_page.dart` |
| 11 | ✅ `test/core/startup/startup_coordinator_test.dart` (Policy, ohne Widget) und `test/features/splash/startup_error_page_test.dart` (Routing bis zum Recovery-Screen) |
