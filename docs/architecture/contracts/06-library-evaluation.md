# Library Evaluation Contract

Bevor eine neue Flutter-Bibliothek Template-Standard wird — oder in einer
abgeleiteten App eine tragende Rolle bekommt — müssen alle Punkte geprüft
und in einer ADR festgehalten sein.

## Prüfliste

1. **Aktiv gewartet.** Aktuelle Releases, erkennbarer Wartungszustand.
   *Gegenbeispiel aus der Praxis:* ein Kalender-Zugriffspaket ohne Release
   seit ~2 Jahren blockierte später das Upgrade eines völlig anderen Pakets.
2. **Kompatible Lizenz** — frei und kommerziell nutzbar (MIT/BSD/Apache-2).
   *Gegenbeispiel:* eine „Community"-Lizenz mit Umsatz- oder
   Mitarbeitergrenzen ist ein Ausschlusskriterium, auch wenn das Paket
   technisch am besten passt.
3. **Kompatibel mit der in CI gepinnten Flutter-/Dart-Version.**
4. **Plattformabdeckung passt zum Ziel** — und dokumentierte
   Plattformgrenzen, statt sie später zu entdecken.
5. **Kein unnötiger Lock-in.** Die genutzte API-Oberfläche muss klein genug
   sein, um sie zu kapseln.
6. **Testbar** — hinter einem Interface fälschbar oder im Widget-Test ohne
   Gerät nutzbar.
7. **Keine unerwarteten Netzwerkzugriffe** und kein Nachladen externer
   Assets zur Laufzeit. Explizit prüfen, nicht annehmen.
8. **Ein Wrapper ist möglich** — und für alles Plattformberührende oder
   Pre-1.0 verpflichtend, abgesichert durch einen Kapselungstest. Muster und
   Beispiele: [Platform Gateways](../patterns/platform-gateways.md).
9. **Keine große Abhängigkeit für ein triviales Problem.**
   *Positivbeispiel:* eine ID-Erzeugung von acht Zeilen statt eines
   UUID-Pakets.
10. **Die transitiven Constraints werden gegen den bestehenden Baum
    geprüft — vorher.** Zwei Pakete können über eine gemeinsame transitive
    Abhängigkeit gegenseitig unauflösbar sein; das fällt sonst erst beim
    nächsten Upgrade auf. Siehe
    [KI-009](../../known-issues.md#ki-009).
11. **Pre-1.0-Pakete werden exakt gepinnt** (kein Caret) und bekommen eine
    dokumentierte Upgrade-/Wiederholbedingung.

## Wann ein Wrapper Pflicht ist

| Art der Bibliothek | Wrapper |
|---|---|
| Plattformoperation (Kontakte, Kalender, Kamera, Billing, Dateien) | **ja** — vollständiges Gateway-Interface |
| Ein-Aufruf-Plugin (Launcher, Share, Clipboard) | **ja** — Typedef-Seam genügt |
| UI-Paket, Pre-1.0 oder mit hoher API-Drift | **ja** — Adapter + Kapselungstest |
| Compile-Time-Generator (Freezed, json_serializable) | nein |
| Reine Dart-Utility (`intl`, `collection`) | nein |

## Entscheidungsdokumentation

Eine ADR zur Bibliothek nennt mindestens: Aufgabe, warum gewählt, geprüfte
Alternativen mit Ablehnungsgrund, Lizenz, Wartungszustand,
Plattformabdeckung, Abstraktionsbedarf, Lock-in-Risiko, Upgrade-Risiko und —
falls gepinnt — die Bedingung, unter der der Pin fällt.

## Stand im Template

Der Vertrag gilt ab sofort für neue Abhängigkeiten. Die bestehenden
Kern-Abhängigkeiten (Riverpod, go_router, Drift, Freezed, `intl`,
`url_launcher`, `share_plus`, `lottie`, `package_info_plus`,
`device_info_plus`, `time_machine2`) sind Bestand und in ADR-0008 bis
ADR-0010 bzw. im README begründet; sie werden nicht rückwirkend neu bewertet.
