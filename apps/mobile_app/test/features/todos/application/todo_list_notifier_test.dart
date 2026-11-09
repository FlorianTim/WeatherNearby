import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/todos/application/todo_list_notifier.dart';
import 'package:mobile_app/features/todos/data/todo_providers.dart';
import 'package:mobile_app/features/todos/domain/todo.dart';
import 'package:mobile_app/features/todos/domain/todo_repository.dart';

class FakeTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];

  @override
  Future<List<Todo>> getAll() async => List.unmodifiable(_todos);

  @override
  Future<Todo?> getById(String id) async =>
      _todos.where((t) => t.id == id).firstOrNull;

  @override
  Future<void> add(Todo todo) async => _todos.add(todo);

  @override
  Future<void> update(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index >= 0) _todos[index] = todo;
  }

  @override
  Future<void> delete(String id) async => _todos.removeWhere((t) => t.id == id);

  @override
  Stream<List<Todo>> watchAll() => Stream.value(List.unmodifiable(_todos));
}

void main() {
  late ProviderContainer container;
  late FakeTodoRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTodoRepository();
    container = ProviderContainer(
      overrides: [todoRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() => container.dispose());

  Future<List<Todo>> readTodos() async {
    // Wait for the provider to complete
    final sub = container.listen(todoListProvider, (_, _) {});
    await container.read(todoListProvider.future);
    final value = sub.read();
    return value.requireValue;
  }

  group('TodoListNotifier', () {
    test('build returns empty list initially', () async {
      final todos = await readTodos();
      expect(todos, isEmpty);
    });

    test('build returns existing todos', () async {
      fakeRepo._todos.add(
        Todo(id: '1', title: 'Existing', createdAt: DateTime(2024, 1, 1)),
      );

      final todos = await readTodos();
      expect(todos.length, 1);
      expect(todos.first.title, 'Existing');
    });

    test('addTodo creates a new todo', () async {
      await readTodos();

      await container
          .read(todoListProvider.notifier)
          .addTodo(title: 'New Task', description: 'A description');

      final todos = await readTodos();
      expect(todos.length, 1);
      expect(todos.first.title, 'New Task');
      expect(todos.first.description, 'A description');
      expect(todos.first.status, TodoStatus.pending);
    });

    test('toggleStatus completes a pending todo', () async {
      final todo = Todo(
        id: '1',
        title: 'Task',
        createdAt: DateTime(2024, 1, 1),
      );
      fakeRepo._todos.add(todo);
      await readTodos();

      await container.read(todoListProvider.notifier).toggleStatus(todo);

      final todos = await readTodos();
      expect(todos.first.status, TodoStatus.completed);
      expect(todos.first.completedAt, isNotNull);
    });

    test('toggleStatus reverts a completed todo to pending', () async {
      final todo = Todo(
        id: '1',
        title: 'Task',
        status: TodoStatus.completed,
        createdAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 2),
      );
      fakeRepo._todos.add(todo);
      await readTodos();

      await container.read(todoListProvider.notifier).toggleStatus(todo);

      final todos = await readTodos();
      expect(todos.first.status, TodoStatus.pending);
      expect(todos.first.completedAt, isNull);
    });

    test('deleteTodo removes the todo', () async {
      fakeRepo._todos.add(
        Todo(id: '1', title: 'To delete', createdAt: DateTime(2024, 1, 1)),
      );
      await readTodos();

      await container.read(todoListProvider.notifier).deleteTodo('1');

      final todos = await readTodos();
      expect(todos, isEmpty);
    });
  });
}
