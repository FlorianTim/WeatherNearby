import 'dart:math';

final _random = Random.secure();

/// RFC 4122 version 4 UUIDs, canonical lowercase.
///
/// ## Why this exists rather than the `uuid` package
///
/// Rule 9 of the
/// [library evaluation contract](../../../../docs/architecture/contracts/06-library-evaluation.md)
/// is "no large dependency for a trivial problem", and its named example is —
/// verbatim — UUID generation. Fifteen lines with a property test satisfy the
/// rule and the standard at the same time.
///
/// ## Why this is not [generateId]
///
/// The app has two kinds of identifier and they must not be confused:
///
/// | | `generateId()` | `Uuid4.generate()` |
/// |---|---|---|
/// | What | a local row id | an identity that survives leaving the app |
/// | Format | 32 hex chars, no contract | RFC 4122 v4, contractual |
/// | Exported | **never** | **always** |
///
/// A row id is a database detail: nothing outside the app ever sees it, so it
/// needs no format. A `uid` is what a shared document is recognized by, and
/// RFC 8984 requires it to be a canonical lowercase v4 UUID. Using one where
/// the other belongs is how a local detail leaks into a shared format, or a
/// shared identity gets regenerated.
abstract final class Uuid4 {
  /// A new version 4 UUID from a cryptographically secure source.
  ///
  /// Canonical lowercase, 36 characters, `8-4-4-4-12`.
  static String generate() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Version 4: the high nibble of byte 6.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Variant 10xx (RFC 4122): the two high bits of byte 8.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// Whether [value] is a canonical lowercase RFC 4122 **version 4** UUID.
  ///
  /// Deliberately strict: an uppercase or braced form is rejected rather than
  /// normalized. A value that reaches storage in a non-canonical form would
  /// compare unequal to the same identity written elsewhere.
  static bool isCanonical(String value) => _canonicalV4.hasMatch(value);

  static final RegExp _canonicalV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
}
