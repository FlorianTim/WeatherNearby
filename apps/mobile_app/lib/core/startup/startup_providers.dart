import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/todos/application/todo_list_notifier.dart';
import '../database/database_provider.dart';
import '../platform/platform_seams.dart';
import 'startup_coordinator.dart';
import 'startup_task.dart';

part 'startup_providers.g.dart';

/// Everything that has to happen before the app shows its first screen.
///
/// **Extend this list per app**, one entry per piece of startup work, and
/// state its [StartupPolicy] deliberately:
///
///  - `blocking` only when the app genuinely cannot continue without it,
///  - `guarded` for caches the first screen would otherwise load lazily,
///  - `fireAndForget` for work nothing on screen depends on.
///
/// Blocking tasks run in this order, so a later one may rely on an earlier
/// one having succeeded.
@Riverpod(keepAlive: true)
List<StartupTask> startupTasks(Ref ref) {
  return [
    StartupTask(
      name: 'database',
      // Opening the connection is what runs `beforeOpen` and the migration.
      // Doing it here, blocking, is what guarantees the database contract's
      // "migrations complete before any dependent read" — every later task
      // and every screen goes through the same provider.
      policy: StartupPolicy.blocking,
      run: () => ref.read(appDatabaseProvider).customSelect('SELECT 1').get(),
    ),
    StartupTask(
      name: 'todo-list',
      // Example primary provider: preloading it means the first screen has
      // no loading flash. If it fails, the screen loads it lazily instead —
      // which is exactly why this is guarded and not blocking.
      policy: StartupPolicy.guarded,
      run: () => ref.read(todoListProvider.future),
    ),
    StartupTask(
      name: 'share-cache-cleanup',
      // Documents queued for sharing are personal free text sitting in a
      // cache directory. Clearing them at startup bounds how long a copy
      // survives after the user has finished with it.
      //
      // fireAndForget: nothing on screen depends on it, and a failure here
      // must never delay or block a start.
      policy: StartupPolicy.fireAndForget,
      run: clearShareCache,
    ),
  ];
}

@Riverpod(keepAlive: true)
StartupCoordinator startupCoordinator(Ref ref) =>
    StartupCoordinator(ref.watch(startupTasksProvider));

/// Outcome of the last startup run; `null` until startup has finished.
///
/// Kept in a provider rather than a local variable because the splash writes
/// it and both the router and the recovery screen read it.
@Riverpod(keepAlive: true)
class StartupOutcome extends _$StartupOutcome {
  @override
  StartupResult? build() => null;

  void record(StartupResult result) => state = result;

  /// Clears the outcome so the splash can run the pipeline again (retry).
  void reset() => state = null;
}
