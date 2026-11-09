## feat(deps): consume task_interchange from flutter-libraries by tag (ADR-0017)

### Warum

Plan 0001 sah als Slice 1 ein eigenes `packages/task_interchange` vor. Derselbe Code liegt jetzt in `flutter-libraries` (Familie `interchange`). Eine Kopie im Template würde von jeder abgeleiteten App wegdriften; eine Abhängigkeit nicht. Dieser PR ersetzt Slice 1 durch die Abhängigkeit und ist der erste Test dieser Abhängigkeit aus Konsumentensicht.

### Was ändert sich

- `apps/mobile_app/pubspec.yaml`: ein `git:`-Block, `ref: interchange-v0.1.0` (`59798a3`); `jscalendar` und `ijson` kommen per relativem Pfad im selben Commit mit. `pubspec.lock` entsprechend.
- `ci-mobile.yml`: übergibt `FLUTTER_LIBRARIES_TOKEN` als `git-read-token`; Shared Workflow vorläufig auf `@v1.6.0` (der bewegliche `v1` enthält den Input noch nicht).
- Neuer Vertragstest `apps/mobile_app/test/interop/interchange_contract_test.dart`: liest die Golden Fixtures aus `.lumbrecode/schemas/` per Verzeichnis; Dekodierung, typisierte Ablehnung der `9x-invalid-`-Fixtures, `encode(decode(x))` == Fixture, unbekanntes Property überlebt.
- ADR-0017 (neu), ADR-0014 teilweise abgelöst, ADR-0011/AGENTS.md verweisen darauf.
- Plan 0001 Slice 1, Spec 0004 (+ Wortlaut in 0001/0003), Teststrategie, `template-initialization.md` und Initializer-Agent: das Paket ist eine Abhängigkeit, die der Initializer behält.
- `docs/operations/local-library-development.md`: Tag-Pin, lokale Entwicklung mit untracked `pubspec_overrides.yaml`, CI-Zugriff, Known-Issues-Prüfung.
- 7 Template-Feedback-Einträge, Feature-Log, Changelog.

Kein UI, keine Änderung an Referenz-App oder App-Shell, kein Bibliothekscode oder Fixture kopiert, `.lumbrecode/` unberührt.

### Getestet

- `scripts/dev/quality_gate.sh`: Format, Analyze, Tests, Help grün.
- `flutter test test/interop`: 71 bestanden, 1 übersprungen (Expected-Summaries, die Baseline 1.5.2 nicht enthält).
- `flutter pub get` / `melos bs` gegen das echte Tag: ~10 s / ~15 s, keine bestehende Version geändert (KI-001/002/009a nicht ausgelöst).

### Bekannte Lücken (Details in `docs/template-feedback/`)

- Secret `FLUTTER_LIBRARIES_TOKEN` muss im Repository existieren, sonst scheitert `pub get`.
- `build-android`, `_android-release-build`, `build-ios`, `dependency-audit`, `copilot-setup-steps` und das Docker-`integration-test` führen `pub get` selbst aus und haben keinen Token-Schritt.
- Baseline 1.5.2 ist älter als die Fixtures der Bibliothek (1.6.0); Exchange-Envelope fehlt in der Bibliothek.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
