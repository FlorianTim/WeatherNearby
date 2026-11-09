# LumbreCode Flutter Template Review

Datum: 2026-07-04 · Reviewer: Claude (Senior-Architektur-/Template-Review) ·
Ablage bewusst unter `drafts/` (non-normativ).

## Executive Summary

- **Gesamtbewertung:** Das Repository ist ein überdurchschnittlich reifes Flutter-Template-Monorepo (Melos + Pub Workspaces, arc42/ADRs, Agents/Skills, CI, Dependabot, Issue-/PR-Templates). Die LumbreCode-spezifischen Anforderungen (Branding, Package-Schema, OpenSpec, Initializer, Zwei-Phasen-Splash, Node-Backend) fehlten vollständig und wurden in diesem Feinschliff ergänzt.
- **Wichtigste Stärken:** Todo-Beispiel-App mit Riverpod 3 (generatorbasiert), Freezed, Drift, go_router und guter Testabdeckung; konsistentes Agent-Regelwerk (AGENTS.md, Copilot-Instructions, Codex-Config); Docker-basierte Build-/Doku-Pipelines; spec-first Workflow.
- **Wichtigste Lücken (vor dem Feinschliff):** Kein LumbreCode-Bezug (project.env enthielt private Beispielwerte), kein Template-Initializer, kein OpenSpec, einphasiger Splash ohne Lottie, kein Node-Backend, `apps/mobile_app/AGENTS.md` in drei Punkten veraltet/widersprüchlich, flutter-create-Reste im Dart-Backend, 8 Workflows ohne `permissions:`-Härtung.
- **Nächste Schritte:** CI auf GitHub laufen lassen (validiert Lottie-/Splash-Änderungen und Node-Backend), `melos run codegen && melos run ci` lokal ausführen, Android/iOS-Native-Projekte per Bootstrap mit den neuen IDs regenerieren, `backend/package-lock.json` committen und CI auf `npm ci` umstellen.

## Template Readiness

- **GitHub-Template-Tauglichkeit:** Gut. README mit "Use this template", Issue-/PR-Templates, Dependabot (jetzt inkl. npm), CODEOWNERS, LICENSE/SECURITY/CONTRIBUTING/CHANGELOG vorhanden, `validate.yml` prüft Pflichtdateien.
- **LumbreCode Branding:** Ergänzt — README-Kopf, `AppBranding` in `packages/app_core` (companyName, companyDomain, basePackage), Company-Splash.
- **Package-Schema:** `de.lumbre.code.<app_slug>` jetzt dokumentiert (README, AGENTS.md, openspec/README.md, project.env) und über `project.env` + Bootstrap-Skripte technisch umgesetzt (`flutter create --org de.lumbre.code --project-name <slug>`).
- **Todo-App als Beispiel-App:** Erhalten und jetzt ausdrücklich als geschützter Template-Bestandteil dokumentiert (Root-AGENTS.md, apps-AGENTS.md, Copilot-Instructions, openspec/apps/todoapp.openspec.yaml).
- **Neue-App-Initialisierung:** Neuer Agent + Doku (`docs/operations/template-initialization.md`) mit Audit/Dry-Run/Apply und Checkliste.

## Splash Screen Review

- **Vorher:** Ein einphasiger Flutter-Splash (App-Titel, Fade-in, fester 2s-Timer), kein Lottie, keine Assets, keine Init-Hook. Nativer Minimal-Splash (launch_background.xml) vorhanden — bleibt korrekt bestehen.
- **Jetzt:** Zweiphasige `SplashPage`: Phase 1 „LumbreCode" (aus `AppBranding`), Phase 2 App-Name (aus l10n `splashTitle`). Gesamtdauer unverändert 2 s (1 s + 1 s, konfigurierbar).
- **Lottie:** `lottie: ^3.3.0` als Dependency; zwei lokale Platzhalter-Animationen unter `assets/animations/` (`lumbrecode_splash_placeholder.json`, `app_splash_placeholder.json`) mit README, klar als austauschbare Platzhalter markiert; `errorBuilder`-Fallback auf Icons, `repeat: false` (testfreundlich). Keine externen URLs.
- **Initialisierung während Splash:** Neuer `initialization`-Hook (`Future<void> Function()?`) — Navigation erst, wenn Mindestdauer UND Init abgeschlossen sind. Timer sind stornierbar (kein „pending timer" in Widget-Tests).
- **Tests:** `test/features/splash/splash_page_test.dart` neu (Phasenwechsel, schnelle Init, langsame Init); `smoke_test.dart` und `app_flow_test.dart` auf die zwei Phasen angepasst.
- **Empfehlung:** Platzhalter bei echtem LumbreCode-Branding ersetzen; optional `flutter_native_splash` für die native Phase evaluieren (bewusst nicht ergänzt — kein Bedarf ohne Branding-Assets).

## Agent and Skill Review

- **Gefunden:** Root- und Bereichs-AGENTS.md (root, apps/mobile_app, services/api), `.github/copilot-instructions.md`, 6 Instructions-Dateien, 3 Agents (planner/implementer/reviewer), 10 Workflow-Skills unter `.github/skills/`, 19 Flutter/Dart-Skills unter `.agents/skills/`, `.codex/config.toml`, `docs/operations/agent-entrypoints.md`. Kein CLAUDE.md/GEMINI.md (unschädlich — AGENTS.md ist der De-facto-Standard und wird referenziert).
- **Konflikte (behoben):** `apps/mobile_app/AGENTS.md` sagte (a) Beispiel-App „komplett ersetzen" inkl. Splash löschen — Widerspruch zum Todo-Erhaltungs-Grundsatz; (b) „kein State-Management-Framework einführen" — Widerspruch zu ADR-0008 (Riverpod) und real genutztem Riverpod 3; (c) „Java-Style `/** */` Doc-Comments" — Widerspruch zum realen Code (durchgehend `///`).
- **Fehlende Regeln (ergänzt):** Generator-Pflichtregeln, Todo-Erhaltungsregel, Splash-/Lottie-Regeln, Template-Identität, OpenSpec-Verweis — alle im Root-AGENTS.md.
- **Template-Initializer:** Neu: `.github/agents/template-initializer.agent.md` (`lumbrecode-template-initializer`), Details unten.
- **Weiterhin offen:** Kein dedizierter Testing-/Documentation-Agent (die Skills decken das teilweise ab — bewusst kein Overengineering).

## OpenSpec Review

- **Vorher:** Kein `openspec/`; stattdessen feature-orientierter spec-first Workflow (`docs/product/specs/`, `docs/delivery/`). Gut für Features, ungeeignet zur App-Initialisierung (keine Felder für app_slug/Package/Splash).
- **Jetzt:** `openspec/` ergänzt: README mit Pflichtfeld-Regel und Validierungs-Checkliste, `templates/app.openspec.yaml` (alle geforderten Felder inkl. `backend_enabled`, `splash_screen_app_name`, `replace_todo_app`), `apps/todoapp.openspec.yaml` als Beispiel und Ist-Zustand.
- **Ableitung:** `app_slug` (Regex `^[a-z][a-z0-9_]*$`) → `de.lumbre.code.<app_slug>`; app_name/display_name/splash-Titel aus der Spec; bei Unklarheit fragt der Initializer nach.
- **replace_todo_app:** Nur im Apply-Modus wirksam, Default `false`, in der Todo-Spec fest `false`.
- **Empfehlung:** Beim ersten echten App-Projekt die Spec-Felder gegen die Praxis prüfen und ggf. `spec_version: 2` iterieren; optional ein Validierungsskript (`scripts/validate_openspec.*`).

## Generator Review

- **Vorhanden und passend:** build_runner, riverpod_annotation + riverpod_generator + riverpod_lint, freezed(+annotation), json_serializable(+annotation), drift_dev, custom_lint, flutter gen-l10n; `melos run codegen[:watch]` orchestriert alles; CI führt codegen aus.
- **Fehlend, aber bewusst nicht ergänzt:** `go_router_builder` (Routen sind zentral in `app_router.dart` — für Template-Größe angemessen; bei wachsender Routenzahl empfehlenswert), `flutter_gen_runner` (erst mit mehr Assets sinnvoll), `mason_cli` (Bricks für Feature-Scaffolding wären der nächste Ausbauschritt), `very_good_cli` (überflüssig — Bootstrap-Skripte existieren).
- **Agent-Regeln:** Die empfohlenen Generator-Regeln (inkl. „nie `*.g.dart`/`*.freezed.dart` editieren", build_runner-Kommando) stehen jetzt verbindlich im Root-AGENTS.md.

## Flutter Feinschliff

- **Riverpod:** Konsistent, generatorbasiert (`@Riverpod`-Annotationen, `.g.dart` committed), Provider-Overrides in Tests vorhanden (`todo_list_page_test.dart` mit FakeRepository) — taugt als Referenzmuster. Keine Business-Logik in Widgets gefunden.
- **Routing:** go_router mit zentralem `goRouterProvider` und `AppRoutes`-Konstanten — sauber, schlank.
- **Models/DTOs:** Freezed + json_serializable am Todo-Model demonstriert.
- **Tests:** Unit (Notifier, Repository, Model), Widget (Page, Splash neu), Integration (Flow + Screenshot-Infrastruktur) — gute Vorlage.
- **Todo-App als Referenz:** Voll funktionsfähig, lokal (Drift), ohne Netzwerkzugriffe — idealer Smoke-Test.
- **Paketstruktur:** Nicht tiefgehend geprüft (außerhalb des Auftrags); keine offensichtlichen Verstöße gegen die dokumentierte feature-first-Struktur.

## Backend Review

- **Vorher:** Nur Dart/Shelf-Service (`services/api/`) mit Health/Config-Endpunkten, Test, Dockerfile — aber verunreinigt durch flutter-create-Reste (web/, windows/-Runner, .metadata). Kein Node.js, kein .env.example.
- **Jetzt:** Reste entfernt (23 Dateien). Neues optionales `backend/` (Node 22, ESM): Express 5 + Zod (Request-/Env-Validierung), `node:test`-Tests gegen echten Listener, ESLint 9 (flat) + Prettier, `.env.example`, README (inkl. Security-Basics, Docker-Snippet, Optionalität), Scripts start/dev/test/lint/format:check/build.
- **Optionalität:** Beide Backends als optional dokumentiert; Auswahl pro App über `backend_flavor` in der OpenSpec; Initializer entfernt das ungenutzte.
- **Offen:** `package-lock.json` konnte hier nicht erzeugt werden (npm-Registry in der Sandbox gesperrt) — nach erstem `npm install` committen und CI auf `npm ci` umstellen.

## CI/CD Review

- **Flutter:** ci-mobile.yml deckt pub get (melos bs), codegen, format-check, analyze, test+coverage ab — entspricht der geforderten Kommandokette. Release-Builds separat (build-android/ios). Läuft mit der Todo-App als Smoke-Test.
- **Backend:** ci-backend.yml (Dart) vorhanden; **neu:** ci-backend-node.yml (install, lint, format:check, test, non-blocking audit), pfadgefiltert auf `backend/**`.
- **Lücken behoben:** 8 Workflows ohne `permissions:` → jetzt überall `contents: read` (bzw. job-lokale Rechte wo nötig).
- **Empfehlungen:** `flutter build web`/`apk --debug` bewusst NICHT in die PR-CI (Kosten/Nutzen — existiert als manueller Workflow); optional concurrency-Gruppen gegen doppelte Läufe.

## Security and Privacy Review

- **Secrets:** Keine echten Secrets im Repo gefunden; `.env`/Keystores/Zertifikate gitignored; `backend/.env.example` neu.
- **Datenschutz:** Privacy-by-default jetzt explizit (SECURITY.md, OpenSpec-Defaults): keine Analytics/Crash-Tools/externen Fonts ohne Opt-in; Todo-App ist vollständig lokal.
- **Third-Party:** Keine externen Runtime-Dienste; Lottie ausschließlich als lokales Asset (dokumentiert in Asset-README, AGENTS.md, SECURITY.md).
- **OWASP:** MASVS (Mobile) und API Security Top 10 (Backend) in SECURITY.md verankert; Logging-Regel (keine Tokens/PII) ergänzt.
- **Lizenz:** MIT vorhanden; Hinweis auf Lizenzreport (`showLicensePage`) ergänzt.
- **Rest-Risiko:** `.gitignore` enthält `*.lock` → `pubspec.lock`/`yarn.lock` werden ignoriert. Für App-Repos (nicht Libraries) empfiehlt Flutter das Committen von `pubspec.lock` — bewusst nicht geändert, siehe Vorschläge.

## Safe Reset Strategy

- **Bleibt immer erhalten:** `.github/` (inkl. Agents/Skills/Workflows), `.codex/`, `.agents/`, `openspec/`, `docs/`, `scripts/`, `packages/`, `infra/`, `tools/`, `design/`, `drafts/`, Root-Konfigurationen (pubspec.yaml, analysis_options.yaml, project.env, docker-compose.yml, VERSION, LICENSE, README/SECURITY/CONTRIBUTING/CHANGELOG), LumbreCode-Splash-Phase, Lottie-Platzhalter-Struktur.
- **Todo-App (ersetzbar nur bei Apply + Spec + replace_todo_app=true):** `lib/features/todos/`, `lib/features/greeting/`, Todo-Anteile in `lib/core/database/`, Todo-l10n-Keys, `test/features/todos/`, Todo-Assertions in `smoke_test`/`integration_test`, `openspec/apps/todoapp.openspec.yaml`.
- **Anzupassen (nicht löschen):** `lib/features/splash/` (App-Phase), `lib/features/settings/`, `pubspec.yaml`-Metadaten, `project.env`, native Projekte (regenerieren).
- **Unklar/gemischt:** `lib/features/home/` (Starter, kaum verdrahtet — Initializer entscheidet je Spec); `integration_test/counter_test.dart` ist Träger der Screenshot-Infrastruktur, referenziert aber den Beispiel-Flow — bei Ersatz Infrastruktur behalten, Flow-Assertions tauschen.
- **Sicherer Ablauf:** audit → dry-run → menschliches Review → apply; Klassifizierung fest im Agenten kodiert; Unklares wird gemeldet, nie gelöscht.

## Recommended Template Initializer Agent

- **Name:** `lumbrecode-template-initializer` (`.github/agents/template-initializer.agent.md`, neu).
- **Eingaben:** company_name/domain/base_package (fix), app_name, app_display_name, app_slug, backend_enabled (+flavor node|dart), replace_todo_app, mode — aus `openspec/apps/<slug>.openspec.yaml`, fehlende Angaben werden abgefragt.
- **Modi:** audit (nur Bericht), dry-run (vollständige Änderungs-/Risikoliste, nichts wird geändert), apply (nur mit vollständiger Spec + explizitem Auftrag).
- **Ablauf apply:** Spec lesen → project.env setzen → native Projekte via Bootstrap regenerieren → pubspec/l10n/Splash-App-Phase setzen → Todo-App klassifiziert ersetzen → Backend-Entscheidung anwenden → `melos run codegen` → `melos run ci` → Doku/CHANGELOG.
- **Sicherheitsregeln:** Nie Template-Infrastruktur oder LumbreCode-Splash löschen; nie generierte Dateien editieren; keine Secrets; keine externen Dienste; Unklares melden statt löschen.

## Concrete Changes Made

Geändert (23): project.env (de.lumbre.code/todoapp + Doku) · apps/mobile_app/pubspec.yaml (lottie, assets) · splash_page.dart (Zwei-Phasen + Init-Hook, komplett neu) · smoke_test.dart, app_flow_test.dart (Phasen-Assertions) · packages/app_core/lib/app_core.dart (Export) · AGENTS.md (Identität, Todo-Regel, Generator-/Splash-Regeln) · apps/mobile_app/AGENTS.md (3 Widersprüche behoben, Ersetzungstabelle) · README.md (LumbreCode-Kopf, Konventionstabelle, Struktur, Next Steps) · SECURITY.md (Baseline erweitert) · CHANGELOG.md · .codex/config.toml (Node-Check) · .github/copilot-instructions.md (Backend-/Todo-Regeln) · .github/dependabot.yml (npm) · services/api/README.md (Optionalität) · 8 Workflows (`permissions: contents: read`).

Neu (16): packages/app_core/lib/src/app_branding.dart · assets/animations/{lumbrecode,app}_splash_placeholder.json + README · test/features/splash/splash_page_test.dart · backend/{package.json, src/app.js, src/config.js, src/server.js, test/app.test.js, .env.example, eslint.config.js, .prettierrc, README.md} · .github/workflows/ci-backend-node.yml · .github/agents/template-initializer.agent.md · openspec/{README.md, templates/app.openspec.yaml, apps/todoapp.openspec.yaml} · docs/operations/template-initialization.md · dieser Bericht.

Gelöscht (23): services/api/{web/, windows/, .metadata} (flutter-create-Reste). Zusätzlich Git-Index-Altlast `melos.yaml` (AD-Zustand) bereinigt.

## Proposed Next Changes

1. `melos run codegen && melos run ci` lokal/CI ausführen — validiert Lottie-Integration und Splash-Tests (hier ohne Flutter SDK nicht möglich).
2. Native Projekte regenerieren: `apps/mobile_app/android/` + `linux/` tragen noch `de.kroschewski.flutter_test_app.test_app`; nach project.env-Update Bootstrap laufen lassen (dokumentiert in template-initialization.md).
3. `pubspec.lock` committen: `*.lock` aus `.gitignore` nehmen oder `!pubspec.lock`-Ausnahme (Flutter-Empfehlung für Apps); ebenso `backend/package-lock.json` erzeugen/committen und CI auf `npm ci` umstellen.
4. Optional: Mason-Bricks für `feature`, `provider`, `model` als nächster Generator-Ausbau; `go_router_builder` bei wachsender Routenzahl.
5. Optional: OpenSpec-Validierungsskript + `validate.yml`-Check auf `openspec/apps/*.yaml`.
6. Echte LumbreCode-Lottie-Animation und App-Icons einpflegen (`flutter_launcher_icons.yaml` existiert bereits).
7. `apps/mobile_app/pubspec.yaml` description ("A new Flutter project.") beim ersten Apply personalisieren.

## Commands Run

| Kommando | Ergebnis | Fehler |
|---|---|---|
| `git status` / `git ls-files` / `git grep` (Inventar) | OK | Initial korrupter Index durch Sandbox-Lock — behoben via Index-Rebuild aus HEAD (Working Tree unberührt) |
| `git rm -r services/api/{web,windows,.metadata}` | OK, 23 Dateien entfernt | — |
| `node --check` (5 Backend-Dateien) | Alle OK | — |
| `npm install` (backend) | **Fehlgeschlagen** | npm-Registry in der Sandbox gesperrt (403). Ursache: Netz-Allowlist. Korrektur: lokal/CI ausführen |
| Python-YAML/JSON-Validierung (13 Workflows, dependabot, OpenSpec, pubspec, Lottie-JSONs, package.json) | ALL VALID | Zwischenzeitlich stale Mount-Cache (pubspec 883 B) — durch Rename-Refresh aufgelöst, Datei vollständig (1083 B) |
| `flutter analyze` / `flutter test` / `dart format` / `build_runner` | **Nicht ausführbar** | Kein Flutter/Dart SDK in der Sandbox. Muss lokal/CI laufen |

## Final Verdict

| Kategorie | Note (1–10) |
|---|---|
| GitHub Template Readiness | 9 |
| Agent/Skill Readiness | 8 |
| OpenSpec Readiness | 7 |
| Generator Readiness | 9 |
| Flutter Template Readiness | 8 |
| Splash Screen Readiness | 8 (Code ungetestet bis CI-Lauf) |
| Backend Readiness | 7 (Node-Basis neu, Lockfile/CI-Lauf ausstehend) |
| CI/CD Readiness | 8 |
| Security/Privacy Readiness | 8 |
| **Overall Readiness** | **8** |

Wichtigster Vorbehalt: Die Flutter-seitigen Änderungen (Lottie, Splash, Tests) sind syntaktisch sorgfältig, aber mangels SDK in dieser Umgebung nicht ausgeführt — der erste `melos run ci`-Lauf ist der Gate-Check.
