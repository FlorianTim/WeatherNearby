import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/database/app_database.dart';
import 'package:mobile_app/features/todos/data/dao/todo_dao.dart';
import 'package:mobile_app/features/todos/data/drift_todo_repository.dart';
import 'package:mobile_app/features/todos/domain/todo.dart';

void main() {
  late AppDatabase db;
  late TodoDao dao;
  late DriftTodoRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TodoDao(db);
    repository = DriftTodoRepository(dao);
  });

  tearDown(() => db.close());

  group('DriftTodoRepository', () {
    test('getAll returns empty list initially', () async {
      final todos = await repository.getAll();
      expect(todos, isEmpty);
    });

    test('add and getAll', () async {
      final todo = Todo(
        id: '1',
        title: 'Test task',
        description: 'Description',
        createdAt: DateTime(2024, 1, 15),
      );

      await repository.add(todo);
      final todos = await repository.getAll();

      expect(todos.length, 1);
      expect(todos.first.id, '1');
      expect(todos.first.title, 'Test task');
      expect(todos.first.description, 'Description');
      expect(todos.first.status, TodoStatus.pending);
    });

    test('getById returns matching todo', () async {
      final todo = Todo(
        id: '42',
        title: 'Find me',
        createdAt: DateTime(2024, 1, 1),
      );
      await repository.add(todo);

      final found = await repository.getById('42');
      expect(found, isNotNull);
      expect(found!.title, 'Find me');
    });

    test('getById returns null for missing id', () async {
      final found = await repository.getById('nonexistent');
      expect(found, isNull);
    });

    test('update modifies existing todo', () async {
      final todo = Todo(
        id: '1',
        title: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );
      await repository.add(todo);

      final updated = todo.copyWith(
        title: 'Updated',
        status: TodoStatus.completed,
        completedAt: DateTime(2024, 1, 2),
      );
      await repository.update(updated);

      final found = await repository.getById('1');
      expect(found!.title, 'Updated');
      expect(found.status, TodoStatus.completed);
      expect(found.completedAt, DateTime(2024, 1, 2));
    });

    test('delete removes the todo', () async {
      await repository.add(
        Todo(id: '1', title: 'To delete', createdAt: DateTime(2024, 1, 1)),
      );

      await repository.delete('1');

      final todos = await repository.getAll();
      expect(todos, isEmpty);
    });

    test('watchAll emits updates', () async {
      final stream = repository.watchAll();

      await repository.add(
        Todo(id: '1', title: 'Streamed', createdAt: DateTime(2024, 1, 1)),
      );

      await expectLater(
        stream,
        emits(
          predicate<List<Todo>>(
            (list) => list.length == 1 && list.first.title == 'Streamed',
          ),
        ),
      );
    });
  });
}
