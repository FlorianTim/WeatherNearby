import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../data/todo_providers.dart';
import '../domain/todo.dart';

part 'todo_list_notifier.g.dart';

@riverpod
class TodoListNotifier extends _$TodoListNotifier {
  @override
  Future<List<Todo>> build() async {
    final repository = ref.watch(todoRepositoryProvider);
    return repository.getAll();
  }

  Future<void> addTodo({required String title, String description = ''}) async {
    final repository = ref.read(todoRepositoryProvider);
    // Id from generateId(), not from a timestamp: two entries created in the
    // same millisecond would otherwise collide, and a timestamp id also ties
    // the identity to a clock that tests move around.
    final todo = Todo(
      id: generateId(),
      title: title,
      description: description,
      createdAt: ref.read(clockProvider).now(),
    );
    await repository.add(todo);
    ref.invalidateSelf();
  }

  Future<void> toggleStatus(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    final updated = todo.copyWith(
      status: todo.status == TodoStatus.completed
          ? TodoStatus.pending
          : TodoStatus.completed,
      completedAt: todo.status == TodoStatus.completed
          ? null
          : ref.read(clockProvider).now(),
    );
    await repository.update(updated);
    ref.invalidateSelf();
  }

  Future<void> deleteTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.delete(id);
    ref.invalidateSelf();
  }
}
