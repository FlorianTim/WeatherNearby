import 'todo.dart';

abstract interface class TodoRepository {
  Future<List<Todo>> getAll();
  Future<Todo?> getById(String id);
  Future<void> add(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(String id);
  Stream<List<Todo>> watchAll();
}
