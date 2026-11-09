import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/todos/domain/todo.dart';

void main() {
  group('Todo', () {
    test('creates with required fields', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final todo = Todo(id: '1', title: 'Test task', createdAt: now);

      expect(todo.id, '1');
      expect(todo.title, 'Test task');
      expect(todo.description, '');
      expect(todo.status, TodoStatus.pending);
      expect(todo.createdAt, now);
      expect(todo.completedAt, isNull);
    });

    test('creates with all fields', () {
      final created = DateTime(2024, 1, 15, 10, 30);
      final completed = DateTime(2024, 1, 15, 14, 0);
      final todo = Todo(
        id: '2',
        title: 'Done task',
        description: 'Some description',
        status: TodoStatus.completed,
        createdAt: created,
        completedAt: completed,
      );

      expect(todo.description, 'Some description');
      expect(todo.status, TodoStatus.completed);
      expect(todo.completedAt, completed);
    });

    test('copyWith produces new instance with changed fields', () {
      final todo = Todo(
        id: '1',
        title: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = todo.copyWith(
        title: 'Updated',
        status: TodoStatus.completed,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated');
      expect(updated.status, TodoStatus.completed);
      expect(todo.title, 'Original');
    });

    test('value equality', () {
      final now = DateTime(2024, 1, 1);
      final a = Todo(id: '1', title: 'Task', createdAt: now);
      final b = Todo(id: '1', title: 'Task', createdAt: now);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('JSON round-trip', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final todo = Todo(
        id: '1',
        title: 'Task',
        description: 'Desc',
        status: TodoStatus.inProgress,
        createdAt: now,
      );

      final json = todo.toJson();
      final restored = Todo.fromJson(json);

      expect(restored, equals(todo));
    });
  });

  group('TodoStatus', () {
    test('has expected values', () {
      expect(TodoStatus.values.length, 3);
      expect(TodoStatus.pending.name, 'pending');
      expect(TodoStatus.inProgress.name, 'inProgress');
      expect(TodoStatus.completed.name, 'completed');
    });
  });
}
