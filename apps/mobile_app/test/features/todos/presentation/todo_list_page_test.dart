import 'package:mobile_app/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/todos/data/todo_providers.dart';
import 'package:mobile_app/features/todos/domain/todo.dart';
import 'package:mobile_app/features/todos/domain/todo_repository.dart';
import 'package:mobile_app/features/todos/presentation/todo_list_page.dart';

class FakeTodoRepository implements TodoRepository {
  List<Todo> todos;
  bool shouldThrow;

  FakeTodoRepository({this.todos = const [], this.shouldThrow = false});

  @override
  Future<List<Todo>> getAll() async {
    if (shouldThrow) throw Exception('Failed to load');
    return todos;
  }

  @override
  Future<Todo?> getById(String id) async =>
      todos.where((t) => t.id == id).firstOrNull;

  @override
  Future<void> add(Todo todo) async => todos = [...todos, todo];

  @override
  Future<void> update(Todo todo) async {
    todos = todos.map((t) => t.id == todo.id ? todo : t).toList();
  }

  @override
  Future<void> delete(String id) async =>
      todos = todos.where((t) => t.id != id).toList();

  @override
  Stream<List<Todo>> watchAll() => Stream.value(todos);
}

Widget buildTestWidget({required FakeTodoRepository repository}) {
  return ProviderScope(
    overrides: [todoRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TodoListPage(onOpenSettings: () {}, onOpenAbout: () {}),
    ),
  );
}

void main() {
  group('TodoListPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = FakeTodoRepository();
      await tester.pumpWidget(buildTestWidget(repository: repo));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty view when no todos', (tester) async {
      final repo = FakeTodoRepository();
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Keine Aufgaben vorhanden'), findsOneWidget);
    });

    testWidgets('shows todo list when data exists', (tester) async {
      final repo = FakeTodoRepository(
        todos: [
          Todo(id: '1', title: 'First task', createdAt: DateTime(2024, 1, 1)),
          Todo(id: '2', title: 'Second task', createdAt: DateTime(2024, 1, 2)),
        ],
      );

      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('First task'), findsOneWidget);
      expect(find.text('Second task'), findsOneWidget);
    });

    testWidgets('shows error view on failure', (tester) async {
      final repo = FakeTodoRepository(shouldThrow: true);
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Fehler beim Laden'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
    });

    testWidgets('FAB opens create dialog', (tester) async {
      final repo = FakeTodoRepository();
      await tester.pumpWidget(buildTestWidget(repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Neue Aufgabe'), findsOneWidget);
      expect(find.text('Titel'), findsOneWidget);
    });
  });
}
