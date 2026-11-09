import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_error_buffer.g.dart';

/// Optional error-infrastructure module.
///
/// `bootstrap()` installs `runZonedGuarded` + `FlutterError.onError` handlers
/// that record uncaught errors here (in memory only — nothing leaves the
/// device). The feedback mail builder (`feedback_mail.dart`) attaches the
/// most recent entry to support mails. Remove this folder if an app does not
/// want the module.

/// One recorded uncaught error.
class AppError {
  AppError({
    required this.error,
    required this.source,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final Object error;
  final StackTrace? stackTrace;

  /// Where the error was caught: 'flutter' (framework) or 'zone' (async).
  final String source;
  final DateTime timestamp;
}

/// Fixed-capacity in-memory buffer of the most recent uncaught errors.
class LastErrorBuffer {
  LastErrorBuffer({this.capacity = 20});

  final int capacity;
  final List<AppError> _entries = [];

  /// Most recent first.
  List<AppError> get entries => List.unmodifiable(_entries.reversed);

  AppError? get last => _entries.isEmpty ? null : _entries.last;

  void add(AppError error) {
    _entries.add(error);
    if (_entries.length > capacity) {
      _entries.removeAt(0);
    }
  }

  void clear() => _entries.clear();
}

/// Overridden in `bootstrap()` with the buffer wired to the zone handlers.
@Riverpod(keepAlive: true)
LastErrorBuffer lastErrorBuffer(Ref ref) => LastErrorBuffer();
