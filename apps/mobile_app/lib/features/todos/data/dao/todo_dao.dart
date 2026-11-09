import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../tables/todo_table.dart';

part 'todo_dao.g.dart';

@DriftAccessor(tables: [TodoItems])
class TodoDao extends DatabaseAccessor<AppDatabase> with _$TodoDaoMixin {
  TodoDao(super.db);

  Future<List<TodoItem>> getAllTodos() => select(todoItems).get();

  Stream<List<TodoItem>> watchAllTodos() => select(todoItems).watch();

  Future<TodoItem?> getTodoById(String id) =>
      (select(todoItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTodo(TodoItemsCompanion entry) =>
      into(todoItems).insert(entry);

  Future<bool> updateTodo(TodoItemsCompanion entry) =>
      update(todoItems).replace(entry);

  Future<int> deleteTodo(String id) =>
      (delete(todoItems)..where((t) => t.id.equals(id))).go();
}
