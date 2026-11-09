/// Feature flags and paid-feature gates.
///
/// Pure Dart on purpose: a gate decision must be unit-testable and
/// overridable without a store, a plugin or a platform channel. Nothing here
/// talks to a billing SDK — a monetization module supplies the current
/// [Entitlement], and this package decides what it unlocks.
library;

/// Simple boolean feature flags.
///
/// Answers "did we ship this feature?", nothing else. Keep it apart from the
/// other states a feature can be in — platform support, permission granted,
/// entitlement held, data available. Collapsing them into one boolean is how
/// "the button does nothing" bugs are born.
class FeatureFlags {
  const FeatureFlags(this._values);

  /// No flags set: every lookup returns `false`.
  const FeatureFlags.empty() : _values = const {};

  final Map<String, bool> _values;

  /// Unknown keys are **off** — a flag has to be switched on deliberately.
  bool isEnabled(String key) => _values[key] ?? false;

  /// The keys this instance knows about (diagnostics, tests).
  Iterable<String> get knownKeys => _values.keys;
}

/// Entitlement levels a user can hold.
///
/// The platform store is the source of truth once purchases exist; app code
/// only ever sees the locally cached value.
enum Entitlement {
  free('free'),
  proLifetime('pro-lifetime'),
  proSubscription('pro-subscription');

  const Entitlement(this.storedValue);

  /// Value written to the settings cache. Stable across enum reordering —
  /// never persist the index.
  ///
  /// Kebab-case because this is a **shared** vocabulary, not a local one:
  /// `schemas/entitlement/v1` in `lumbrecode-engineering` (synchronized into
  /// `.lumbrecode/`) is what every LumbreCode app writes, on every stack. A
  /// Flutter app and a web app belonging to one product must not disagree on
  /// how "lifetime Pro" is spelled.
  final String storedValue;

  /// Any paid entitlement counts as Pro.
  bool get isPro => this != Entitlement.free;

  /// Whether this entitlement satisfies [required].
  bool satisfies(Entitlement required) => required == Entitlement.free || isPro;

  /// Values written before the vocabulary was shared.
  ///
  /// Template 3.2.1 stored `pro_lifetime`. Dropping the mapping would decode
  /// it to [free] — silently downgrading somebody who paid, which is the one
  /// direction this cache must never fail in. Costs two map entries; remove
  /// them only once no installation can still hold the old form.
  static const _legacyStoredValues = {
    'pro_lifetime': Entitlement.proLifetime,
    'pro_subscription': Entitlement.proSubscription,
  };

  /// Unknown or missing values degrade to [free] instead of throwing.
  static Entitlement fromStored(String? value) {
    for (final entitlement in values) {
      if (entitlement.storedValue == value) return entitlement;
    }
    return _legacyStoredValues[value] ?? Entitlement.free;
  }
}

/// Maps gated feature keys to the entitlement they require.
///
/// **Fail-open by design:** a key that is not in the catalog is always
/// unlocked. A typo in a feature key must never lock a user out of a core
/// feature — the worst case is that a paid feature stays free until the
/// catalog is corrected, which is recoverable; the opposite is not.
class FeatureGates {
  const FeatureGates(this._requiredEntitlements);

  /// Nothing gated — the sensible default for a new app.
  const FeatureGates.none() : _requiredEntitlements = const {};

  final Map<String, Entitlement> _requiredEntitlements;

  /// Whether [featureKey] is available under [current].
  bool isUnlocked(String featureKey, Entitlement current) {
    final required = _requiredEntitlements[featureKey];
    if (required == null) return true;
    return current.satisfies(required);
  }

  /// The gated feature keys (diagnostics, tests).
  Iterable<String> get gatedKeys => _requiredEntitlements.keys;

  /// The catalog shipped with the app.
  ///
  /// Declare keys here **before** enforcement is switched on, so call sites
  /// and tests already exist when the first paid feature lands:
  ///
  /// ```dart
  /// static const shipped = FeatureGates({
  ///   'backup.export': Entitlement.proLifetime,
  /// });
  /// ```
  static const shipped = FeatureGates.none();
}
