import 'dart:math';

final _random = Random.secure();

/// Generates a random 32-character hex id (128 bit) for local rows.
///
/// Why not a UUID package: eight lines of `Random.secure()` cover the entire
/// need — a stable, collision-free-in-practice identifier for on-device data.
/// Pulling a dependency for this would fail rule 9 of the
/// [library evaluation contract](../../../../docs/architecture/contracts/06-library-evaluation.md).
///
/// Why app-generated ids at all
/// (`docs/architecture/contracts/02-database.md`, rule 4):
///
///  - They are stable from insert onwards, so they can be referenced
///    externally (deep links, exports) without ever changing.
///  - They are independent of any external system. An id derived from a
///    provider's id breaks the moment that provider changes, disappears, or a
///    second provider is added.
///  - They are not reused, so a deleted row's id can never resurface pointing
///    at different data.
String generateId() {
  final buffer = StringBuffer();
  for (var i = 0; i < 8; i++) {
    buffer.write(_random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'));
  }
  return buffer.toString();
}
