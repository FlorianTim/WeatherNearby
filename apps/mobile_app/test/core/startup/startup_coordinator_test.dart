import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/startup/startup_coordinator.dart';
import 'package:mobile_app/core/startup/startup_task.dart';

/// The coordinator is plain Dart, so its policy can be proven without
/// pumping a widget or opening a database.
void main() {
  StartupTask task(
    String name,
    StartupPolicy policy, {
    required List<String> log,
    Object? throws,
  }) {
    return StartupTask(
      name: name,
      policy: policy,
      run: () async {
        log.add(name);
        if (throws != null) throw throws;
      },
    );
  }

  test('blocking tasks run sequentially in registration order', () async {
    final log = <String>[];

    final result = await StartupCoordinator([
      task('first', StartupPolicy.blocking, log: log),
      task('second', StartupPolicy.blocking, log: log),
    ]).run();

    expect(log, ['first', 'second']);
    expect(result.isFatal, isFalse);
  });

  test(
    'a failing blocking task is fatal and stops the ones after it',
    () async {
      final log = <String>[];

      final result = await StartupCoordinator([
        task('database', StartupPolicy.blocking, log: log, throws: 'boom'),
        task('never-runs', StartupPolicy.blocking, log: log),
        task('also-never-runs', StartupPolicy.guarded, log: log),
      ]).run();

      // Later tasks may depend on the failed one; running them would only
      // produce follow-up errors that mask the real cause.
      expect(log, ['database']);
      expect(result.isFatal, isTrue);
      expect(result.fatal!.taskName, 'database');
      expect(result.fatal!.error, 'boom');
    },
  );

  test('a failing guarded task degrades but does not abort startup', () async {
    final log = <String>[];

    final result = await StartupCoordinator([
      task('cache-a', StartupPolicy.guarded, log: log, throws: 'nope'),
      task('cache-b', StartupPolicy.guarded, log: log),
    ]).run();

    expect(log, containsAll(<String>['cache-a', 'cache-b']));
    expect(result.isFatal, isFalse);
    expect(result.degraded, hasLength(1));
    expect(result.degraded.single.taskName, 'cache-a');
  });

  test('guarded tasks run in parallel, not one after the other', () async {
    var running = 0;
    var maxConcurrent = 0;

    StartupTask concurrent(String name) => StartupTask(
      name: name,
      policy: StartupPolicy.guarded,
      run: () async {
        running++;
        maxConcurrent = maxConcurrent > running ? maxConcurrent : running;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        running--;
      },
    );

    await StartupCoordinator([
      concurrent('a'),
      concurrent('b'),
      concurrent('c'),
    ]).run();

    expect(maxConcurrent, 3);
  });

  test('fireAndForget tasks do not delay the result', () async {
    final completed = <String>[];

    final result = await StartupCoordinator([
      StartupTask(
        name: 'background',
        policy: StartupPolicy.fireAndForget,
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          completed.add('background');
        },
      ),
    ]).run();

    // run() returned before the task finished — that is the point.
    expect(completed, isEmpty);
    expect(result.isFatal, isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(completed, ['background']);
  });

  test('a failing fireAndForget task never surfaces', () async {
    final result = await StartupCoordinator([
      StartupTask(
        name: 'background',
        policy: StartupPolicy.fireAndForget,
        run: () async => throw StateError('ignored'),
      ),
    ]).run();

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(result.isFatal, isFalse);
    expect(result.degraded, isEmpty);
  });

  test('an empty pipeline succeeds', () async {
    expect((await const StartupCoordinator([]).run()).isFatal, isFalse);
  });
}
