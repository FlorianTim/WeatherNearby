# ADR 0010: Deklaratives Routing mit go_router

## Status

Angenommen

## Kontext

Die bisherige Navigation nutzte manuelles Enum-basiertes Screen-Switching im
Root-Widget. Dies skaliert nicht für Deep Links, Shell Routes, Auth-Guards
oder Web-URLs.

## Entscheidung

go_router wird als deklaratives Routing-Framework eingesetzt.

- Routen werden in `lib/app/router/` zentral definiert
- Route-Pfade liegen als Konstanten in `routes.dart`
- Bestehende Pages behalten ihr Callback-Interface; die Verdrahtung mit
  `context.go(...)` erfolgt im Router-Builder
- Der GoRouter-Instanz wird als Riverpod-Provider bereitgestellt

## Konsequenzen

### Positiv

- Deep-Link-fähig (Web, Mobile Universal Links)
- Modular erweiterbar (Feature-Routen, Guards, Redirects)
- ShellRoute für verschachtelte Navigation (Bottom Nav, Tabs)
- Testbar über Router-Konfiguration

### Negativ

- Zusätzliche Abstraktion über Navigator 2.0
- Leichte Migration der bestehenden Callback-Verdrahtung nötig
- MaterialApp.router statt MaterialApp.home (Tests müssen angepasst werden)
