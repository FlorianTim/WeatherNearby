import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/todo.dart';

extension TodoItemMapper on TodoItem {
  Todo toDomain() => Todo(
    id: id,
    title: title,
    description: description,
    status: TodoStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => TodoStatus.pending,
    ),
    createdAt: createdAt,
    completedAt: completedAt,
  );
}

extension TodoToCompanion on Todo {
  TodoItemsCompanion toCompanion() => TodoItemsCompanion(
    id: Value(id),
    title: Value(title),
    description: Value(description),
    status: Value(status.name),
    createdAt: Value(createdAt),
    completedAt: completedAt != null
        ? Value(completedAt!)
        : const Value.absent(),
  );
}
