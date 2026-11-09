// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todoDao)
const todoDaoProvider = TodoDaoProvider._();

final class TodoDaoProvider
    extends $FunctionalProvider<TodoDao, TodoDao, TodoDao>
    with $Provider<TodoDao> {
  const TodoDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoDaoHash();

  @$internal
  @override
  $ProviderElement<TodoDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TodoDao create(Ref ref) {
    return todoDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoDao>(value),
    );
  }
}

String _$todoDaoHash() => r'873f8c5d7a19ebf7b4647d3e0025a953d2e78ef6';

@ProviderFor(todoRepository)
const todoRepositoryProvider = TodoRepositoryProvider._();

final class TodoRepositoryProvider
    extends $FunctionalProvider<TodoRepository, TodoRepository, TodoRepository>
    with $Provider<TodoRepository> {
  const TodoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoRepositoryHash();

  @$internal
  @override
  $ProviderElement<TodoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TodoRepository create(Ref ref) {
    return todoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoRepository>(value),
    );
  }
}

String _$todoRepositoryHash() => r'7925a92ed95d7da1a7070424949c64c461694475';
