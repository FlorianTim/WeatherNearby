import 'package:feature_flags/feature_flags.dart';

/// Platform billing behind an app-owned interface (spec 0007, ADR-0015).
///
/// App code never talks to a billing SDK — only an adapter behind this
/// interface does, and the template ships **no such adapter**. Adding one is
/// a bounded change: one dependency, one file, one provider override. See
/// `docs/architecture/patterns/in-app-purchase-gateway.md`.
///
/// Two calls, both user-triggered. No stream, no listener, no pending-purchase
/// queue: those only mean something once purchases exist, and shipping them
/// now would be untested surface the real adapter would then have to match.
abstract interface class PurchaseGateway {
  /// Whether platform billing is reachable.
  ///
  /// Called only on an explicit user action — opening the Pro page — and
  /// **never during startup** (IAP-005). A platform call in the startup path
  /// is how a splash screen starts hanging on a device without store
  /// services.
  Future<bool> isStoreAvailable();

  /// Asks the store for a previously bought entitlement.
  ///
  /// Returns what the store reports, or [Entitlement.free] when it reports
  /// nothing. Implementations must not throw for "no store" — that is an
  /// expected answer, not an error.
  Future<Entitlement> restorePurchases();
}

/// The gateway the template runs.
///
/// Not a stub that throws: this is the **correct** implementation for a
/// device with no store services and for the web target, and it is what an
/// app without billing keeps forever.
class UnavailablePurchaseGateway implements PurchaseGateway {
  const UnavailablePurchaseGateway();

  @override
  Future<bool> isStoreAvailable() async => false;

  @override
  Future<Entitlement> restorePurchases() async => Entitlement.free;
}

/// Deterministic gateway for tests.
///
/// Includes a failure mode on purpose: "the store call threw" is the case
/// that produces the ugliest bugs, and a fake that cannot reproduce it lets
/// them through.
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    this.storeAvailable = false,
    this.restored = Entitlement.free,
    this.throws = false,
  });

  final bool storeAvailable;
  final Entitlement restored;

  /// When set, both calls throw — as a plugin does when the platform channel
  /// is missing.
  final bool throws;

  /// Call log, so a test can assert that the store is **not** queried during
  /// startup (IAP-005).
  final List<String> calls = [];

  @override
  Future<bool> isStoreAvailable() async {
    calls.add('isStoreAvailable');
    if (throws) throw StateError('no platform channel');
    return storeAvailable;
  }

  @override
  Future<Entitlement> restorePurchases() async {
    calls.add('restorePurchases');
    if (throws) throw StateError('no platform channel');
    return restored;
  }
}
