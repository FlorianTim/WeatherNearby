# Architecture Plan: Flutter App Modernization

## Current State (Before)

- **State Management**: `setState` in root widget
- **Routing**: Manual enum-based screen switching
- **Persistence**: None
- **Code Generation**: Only `flutter gen-l10n`
- **Structure**: Feature-first with `presentation/` only

## Target State (After)

- **State Management**: Riverpod (AsyncNotifier, Notifier, Provider)
- **Routing**: go_router with declarative routes
- **Persistence**: Drift/SQLite (Offline-First)
- **Code Generation**: freezed, json_serializable, riverpod_generator, drift_dev
- **Structure**: Feature-first with 4 layers (Presentation, Application, Domain, Data)

## Layer Architecture

```
┌────────────────────────────────────────────────────┐
│  Presentation (Widgets, Pages, ConsumerWidget)     │
│  - Watches providers, renders AsyncValue states    │
│  - Triggers actions via notifier methods           │
├────────────────────────────────────────────────────┤
│  Application (AsyncNotifier, Notifier)             │
│  - Coordinates use cases and repository calls      │
│  - Manages UI-relevant async state                 │
├────────────────────────────────────────────────────┤
│  Domain (Models, Repository interfaces, Enums)     │
│  - Pure Dart, no Flutter/Drift/HTTP dependencies   │
│  - Defines the business contract                   │
├────────────────────────────────────────────────────┤
│  Data (Repository impl, DAO, DTOs, Mappers)        │
│  - Concrete DB/API access via Drift, HTTP, etc.    │
│  - Maps between persistence models and domain      │
└────────────────────────────────────────────────────┘
```

## Feature Structure

```
lib/features/<feature_name>/
  domain/
    <model>.dart              # @freezed domain model
    <feature>_repository.dart # abstract interface class
  data/
    tables/                   # Drift table definitions
    dao/                      # Drift DAOs
    mapper/                   # Domain ↔ DB conversion
    drift_<feature>_repository.dart
    <feature>_providers.dart  # @riverpod DAO + Repository providers
  application/
    <feature>_notifier.dart   # @riverpod AsyncNotifier
  presentation/
    <feature>_page.dart       # ConsumerWidget
    widgets/                  # Feature-specific UI components
```

## Dependency Flow

```
UI → Application → Domain ← Data
                     ↑          ↓
              (abstract)    (concrete)
```

- UI imports Application + Domain
- Application imports Domain
- Data implements Domain interfaces
- Data is wired to Domain via Riverpod providers

## Key Packages

| Package | Role |
|---------|------|
| flutter_riverpod | State management + DI |
| riverpod_annotation + riverpod_generator | Code-gen for providers |
| go_router | Declarative routing |
| freezed + freezed_annotation | Immutable models, copyWith, unions |
| json_annotation + json_serializable | JSON serialization |
| drift + drift_flutter | Local SQLite persistence |
| mocktail | Testing mocks |

## Testing Strategy

| Layer | Test Type | Approach |
|-------|-----------|----------|
| Domain | Unit | Direct model construction, JSON round-trip |
| Application | Unit | ProviderContainer + repository override |
| Data | Integration | In-memory Drift DB (`NativeDatabase.memory()`) |
| Presentation | Widget | ProviderScope with fake repos, test AsyncValue states |
| E2E | Smoke | Full app via `const App()`, validates navigation flow |

## Implemented First Slice: Todos

Demonstrates the complete architecture with:
- `@freezed` Todo model with TodoStatus enum
- `TodoRepository` abstract interface
- Drift table + DAO + DriftTodoRepository
- `TodoListNotifier` (AsyncNotifier) with CRUD operations
- `TodoListPage` with loading/error/data/empty states
- Full test coverage across all layers
