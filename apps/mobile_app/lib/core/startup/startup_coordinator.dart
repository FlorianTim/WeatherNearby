import 'dart:async';

import 'package:flutter/foundation.dart';

import 'startup_task.dart';

/// Runs the registered [StartupTask]s in three phases.
///
/// ```
/// phase 1  blocking       sequential, in registration order — a failure is fatal
/// phase 2  guarded        parallel — failures are collected, startup continues
/// phase 3  fireAndForget  not awaited — failures are swallowed
/// ```
///
/// Why this exists rather than an inline closure in the router: the three
/// treatments above are the entire startup policy of the app, and they were
/// previously implicit in whether somebody wrote `await`, `unawaited` or a
/// `try/catch`. Making them a declared property of each task means a new
/// feature has to state how its startup work may fail, and the recovery
/// behaviour is testable without pumping a widget.
///
/// Every failure is also written to the debug console. The recovery screen
/// deliberately shows only the task name, so without this line a failing
/// start leaves no trace at all to debug from — which is the difference
/// between "step `database` failed" and a message naming the cause.
///
/// The coordinator itself is plain Dart with no Riverpod inside, so it can be
/// unit-tested with hand-made tasks (see
/// `test/core/startup/startup_coordinator_test.dart`).
class StartupCoordinator {
  const StartupCoordinator(this.tasks);

  final List<StartupTask> tasks;

  Future<StartupResult> run() async {
    final degraded = <StartupFailure>[];

    for (final task in _withPolicy(StartupPolicy.blocking)) {
      try {
        await task.run();
      } catch (error, stackTrace) {
        _report(task, error, stackTrace);
        // Stop here: later blocking tasks may depend on this one, and running
        // them would only produce follow-up errors that mask the real cause.
        return StartupResult(
          degraded: degraded,
          fatal: StartupFailure(
            taskName: task.name,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    await Future.wait([
      for (final task in _withPolicy(StartupPolicy.guarded))
        _runGuarded(task, degraded),
    ]);

    for (final task in _withPolicy(StartupPolicy.fireAndForget)) {
      unawaited(_runGuarded(task, <StartupFailure>[]));
    }

    return StartupResult(degraded: degraded);
  }

  Iterable<StartupTask> _withPolicy(StartupPolicy policy) =>
      tasks.where((task) => task.policy == policy);

  /// Number of stack frames written to the console per failure.
  ///
  /// The cause is always in the top frames; the rest is framework plumbing —
  /// and under `flutter_test` a full trace is several hundred lines that
  /// bury the message itself.
  static const int _reportedFrames = 12;

  static void _report(StartupTask task, Object error, StackTrace stackTrace) {
    final frames = stackTrace.toString().trimRight().split('\n');
    final shown = frames.take(_reportedFrames).join('\n');
    final omitted = frames.length - _reportedFrames;
    debugPrint(
      'Startup task "${task.name}" failed: $error\n$shown'
      '${omitted > 0 ? '\n... $omitted more frames' : ''}',
    );
  }

  static Future<void> _runGuarded(
    StartupTask task,
    List<StartupFailure> sink,
  ) async {
    try {
      await task.run();
    } catch (error, stackTrace) {
      _report(task, error, stackTrace);
      sink.add(
        StartupFailure(
          taskName: task.name,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
