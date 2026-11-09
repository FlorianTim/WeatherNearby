import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

enum TodoStatus { pending, inProgress, completed }

@freezed
abstract class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    @Default('') String description,
    @Default(TodoStatus.pending) TodoStatus status,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}
