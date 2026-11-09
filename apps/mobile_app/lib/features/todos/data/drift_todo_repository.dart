import '../domain/todo.dart';
import '../domain/todo_repository.dart';
import 'dao/todo_dao.dart';
import 'mapper/todo_mapper.dart';

class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._dao);

  final TodoDao _dao;

  @override
  Future<List<Todo>> getAll() async {
    final rows = await _dao.getAllTodos();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Todo?> getById(String id) async {
    final row = await _dao.getTodoById(id);
    return row?.toDomain();
  }

  @override
  Future<void> add(Todo todo) async {
    await _dao.insertTodo(todo.toCompanion());
  }

  @override
  Future<void> update(Todo todo) async {
    await _dao.updateTodo(todo.toCompanion());
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteTodo(id);
  }

  @override
  Stream<List<Todo>> watchAll() {
    return _dao.watchAllTodos().map(
      (rows) => rows.map((r) => r.toDomain()).toList(),
    );
  }
}
