# feature_flags

Boolean feature flags plus the paid-feature gate catalog (`Entitlement`,
`FeatureGates`).

**Classification: baseline — keep.**

Pure Dart, no plugin, no backend. Gate decisions have to be unit-testable and
overridable without a store SDK, which is exactly what this package is for.
Entitlements come from the platform store, not from a server, so a
backend-less app needs them just as much as one with an API.

`FeatureGates` is **fail-open**: a key that is not in the catalog is always
unlocked, so a typo in a feature key can never lock a user out of a core
feature.

`scripts/remove_backend.*` therefore leaves this package alone.
