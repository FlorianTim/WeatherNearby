# Android-Ressourcen-Vorlagen

Diese Dateien werden von `bootstrap_android.*` nach dem `flutter create` in
`apps/mobile_app/android/app/src/main/res/` kopiert. Sie sind der einzige
Android-spezifische Teil des Brandings — alles andere entsteht mit
Flutter-Bordmitteln:

| Was | Womit |
|---|---|
| Launcher-Icons (alle Dichten, adaptive, monochrom) | `flutter_launcher_icons` |
| In-App-Splash (zwei Phasen) | Flutter-Widget, `lib/features/splash/` |
| **Android-12+-System-Splash** | **diese Vorlagen** — kein Flutter-Äquivalent |
| **Launch-Window vor Android 12** | **diese Vorlagen** — kein Flutter-Äquivalent |

Warum es kein Flutter-Äquivalent gibt: Der System-Splash ab API 31 wird vom
Betriebssystem gezeichnet, **bevor** die Flutter-Engine läuft. Er ist
ausschließlich über Theme-Attribute in `res/values-v31/` konfigurierbar.
Dasselbe gilt für das Fenster davor.

## Dateien

| Datei | Zweck |
|---|---|
| `values/splash_colors.xml` | Die eine Hintergrundfarbe. **Eigene Datei**, damit `flutter_launcher_icons` beim Schreiben von `values/colors.xml` nichts überschreibt. |
| `values/styles.xml` | `LaunchTheme` (vor dem ersten Frame) und `NormalTheme` (dahinter) |
| `values-night/styles.xml` | Dunkelmodus, absichtlich identisch |
| `values-v31/styles.xml` | Android 12+: `windowSplashScreenBackground` und `windowSplashScreenAnimatedIcon` |
| `values-night-v31/styles.xml` | ⚠️ **Ohne diese Datei** gewinnt im Dunkelmodus auf Android 12+ das `values-night`-Theme und die Splash-Attribute fallen ersatzlos weg. |
| `drawable/launch_background.xml` | Fensterhintergrund vor Android 12 |

## Farbe anpassen

Nur an einer Stelle: `values/splash_colors.xml`. Der Wert muss mit dem
Hintergrund der In-App-Splash-Animation übereinstimmen, sonst blitzt beim
Übergang ein andersfarbiger Frame auf. Vorgabe ist die
LumbreCode-Markenfarbe `#070A10` — dieselbe wie
`adaptive_icon_background` in `flutter_launcher_icons.yaml`.

## Splash-Icon

`windowSplashScreenAnimatedIcon` zeigt auf `@mipmap/ic_launcher`, also auf
das Icon, das `flutter_launcher_icons` ohnehin erzeugt. Kein zusätzliches
Asset, kein Generator.

Android maskiert das Splash-Icon auf einen Kreis über dem inneren Drittel
der Fläche. Das adaptive Icon ist genau dafür gebaut — ein Motiv, das den
Rand ausreizt, wird hier beschnitten.
`windowSplashScreenIconBackgroundColor` ist bewusst **nicht** gesetzt: ohne
Icon-Hintergrund gibt Android dem Icon mehr sichtbare Fläche.

## Ablauf

```
scripts/bootstrap_android.sh
  └─ flutter create (Temp-Verzeichnis)  →  android/ kopieren
  └─ diese Vorlagen einkopieren
  └─ AndroidManifest: android:allowBackup setzen
danach von Hand:
  cd apps/mobile_app && dart run flutter_launcher_icons
```

Wiederholbar: jeder Bootstrap-Lauf legt die Dateien erneut an.
