import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database_provider.dart';
import '../domain/todo_repository.dart';
import 'dao/todo_dao.dart';
import 'drift_todo_repository.dart';

part 'todo_providers.g.dart';

@riverpod
TodoDao todoDao(Ref ref) => TodoDao(ref.watch(appDatabaseProvider));

@riverpod
TodoRepository todoRepository(Ref ref) =>
    DriftTodoRepository(ref.watch(todoDaoProvider));
