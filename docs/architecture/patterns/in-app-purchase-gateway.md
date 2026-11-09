# Recipe: adding real in-app purchases

> **Status:** recipe, not template code. The template ships the seam —
> `PurchaseGateway`, the entitlement cache, the gate catalogue and the Pro
> page — and deliberately **no billing dependency** (ADR-0015).
>
> Follow this when a derived app actually sells something.

## What already exists, and what you add

| Piece | Where | Ships with the template |
|---|---|---|
| `PurchaseGateway` interface | `features/monetization/data/purchase_gateway.dart` | yes |
| `UnavailablePurchaseGateway` (no store, and web) | same file | yes |
| `FakePurchaseGateway` (tests, incl. a failure mode) | same file | yes |
| Entitlement cache + `checkedAt` | `core/settings/app_settings.dart` | yes |
| `featureUnlocked(key)`, fail-open gates | `features/monetization/application/` | yes |
| Pro page (status only) | `features/monetization/presentation/pro_page.dart` | yes |
| **The plugin adapter** | a new file next to the interface | **no — this recipe** |

Adding billing changes **one provider override**. No call site changes,
because there are no call sites outside the page: app code asks
`featureUnlocked(key)` and nothing else (IAP-020).

## Step 1 — the dependency

```yaml
# apps/<app>/pubspec.yaml
dependencies:
  in_app_purchase: ^3.2.0
```

Read `docs/architecture/contracts/06-library-evaluation.md` first, and record
the evaluation in the PR. This is a plugin with platform manifests and store
declarations behind it — the one class of dependency the contract asks you to
justify in writing.

## Step 2 — the adapter

One file, and the **only** place in the app that may import the plugin.

```dart
// lib/features/monetization/data/in_app_purchase_gateway.dart
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_gateway.dart';

/// The only file in the app that touches the billing plugin (IAP-001).
class InAppPurchaseGateway implements PurchaseGateway {
  const InAppPurchaseGateway();

  @override
  Future<bool> isStoreAvailable() async {
    // No web implementation: the dev/testing web target must degrade
    // gracefully rather than throw.
    if (kIsWeb) return false;
    try {
      return await InAppPurchase.instance.isAvailable();
    } catch (_) {
      // Missing store services or platform channel: unavailable, not an
      // error. "The store is unreachable" is an answer (IAP-006).
      return false;
    }
  }

  @override
  Future<Entitlement> restorePurchases() async {
    if (kIsWeb) return Entitlement.free;
    try {
      await InAppPurchase.instance.restorePurchases();
      // Restored purchases arrive on `purchaseStream`. Map your product ids
      // to entitlements there and return the highest one found; return
      // Entitlement.free when the stream yields nothing within your timeout.
      return await _entitlementFromStream();
    } catch (_) {
      return Entitlement.free;
    }
  }
}
```

Keep the plugin's types inside this file. A `ProductDetails` in a widget
signature is how the encapsulation is lost.

## Step 3 — point the provider at it

```dart
// lib/features/monetization/application/monetization_providers.dart
@Riverpod(keepAlive: true)
PurchaseGateway purchaseGateway(Ref ref) => const InAppPurchaseGateway();
```

That is the whole wiring change.

## Step 4 — the guardrail test

`test/features/monetization/billing_dependency_test.dart` currently asserts
that **no** billing package is imported anywhere. Turn it into a normal
encapsulation test rather than deleting it:

```dart
expectPackageEncapsulated(
  package: 'in_app_purchase',
  allowedDirectory: 'lib/features/monetization/data',
);
```

## Step 5 — platform and store setup

Not code, and the part that takes the longest:

- **Android:** the `com.android.vending.BILLING` permission, a signed build
  uploaded to a test track, a licence tester account, and products created in
  the Play Console. Billing does not work from a debug build installed by
  `flutter run`.
- **iOS:** In-App Purchase capability, products created in App Store Connect,
  the Paid Apps agreement signed, and a sandbox tester account.
- Both stores review the purchase flow. A screen that mentions a price
  without a working purchase is a rejection reason — which is why the
  template's Pro page shows neither.

## Step 6 — extend the page

Only now does `pro_page.dart` gain products, prices and a buy action. Until
that step it stays what it is: an honest status page.

## What stays true afterwards

- `Entitlement` decoding stays fail-safe (`free` on anything unknown). The
  cache is a cache; the store is the source of truth.
- `billing.checkedAt` gets its first real value. Decide the re-verification
  interval then — spec 0007's Q5 leaves it open on purpose.
- The gate catalogue stays fail-open. A typo in a feature key must never lock
  a user out of a core feature.
- `isStoreAvailable()` is still called only on explicit user action, never
  during startup (IAP-005).
