/// How a startup task is allowed to fail.
///
/// The distinction is the whole point of the coordinator: "the database
/// could not be opened" and "preloading the list failed" must not be handled
/// the same way, and deciding that at the call site is how one of them ends
/// up silently swallowed.
enum StartupPolicy {
  /// Must succeed before the app may navigate.
  ///
  /// Runs sequentially in registration order, so a task may rely on the ones
  /// before it. The first failure aborts startup and leads to the recovery
  /// screen — nothing after it runs.
  blocking,

  /// Runs before navigation, but a failure only degrades the app.
  ///
  /// Executed in parallel; failures are collected and reported, never
  /// rethrown. Typical use: warming caches so the first screen renders
  /// without a loading flash. If it fails, the data simply loads lazily.
  guarded,

  /// Started and not awaited; navigation does not wait for it.
  ///
  /// Failures are swallowed. Typical use: background reconciliation whose
  /// result nothing on the first screen depends on.
  fireAndForget,
}

/// One unit of startup work.
///
/// [name] appears in diagnostics and on the recovery screen, so it must be a
/// technical, stable identifier — never a user name, a file path or anything
/// else personal.
class StartupTask {
  const StartupTask({
    required this.name,
    required this.policy,
    required this.run,
  });

  final String name;
  final StartupPolicy policy;
  final Future<void> Function() run;
}

/// A task that did not complete.
class StartupFailure {
  const StartupFailure({
    required this.taskName,
    required this.error,
    this.stackTrace,
  });

  final String taskName;
  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'StartupFailure($taskName: $error)';
}

/// What startup produced.
class StartupResult {
  const StartupResult({this.degraded = const [], this.fatal});

  /// Everything went through.
  static const StartupResult ok = StartupResult();

  /// Guarded tasks that failed. The app runs, but something is missing.
  final List<StartupFailure> degraded;

  /// The blocking task that aborted startup, if any.
  final StartupFailure? fatal;

  /// Whether the app must show the recovery screen instead of its first
  /// real screen.
  bool get isFatal => fatal != null;
}
