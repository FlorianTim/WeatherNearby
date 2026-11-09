# Data contract: In-app purchase placeholder

## Stored data

Two keys in the existing `AppSettings` register. No database change.

| Key | Type | Encoding | Default |
|---|---|---|---|
| `billing.entitlement` | `Entitlement` | the enum's stable `storedValue` | `free` |
| `billing.checkedAt` | `DateTime?` | UTC ISO-8601 | `null` |

### Stable values

`Entitlement.storedValue` already exists in `packages/feature_flags`:

| Enum value | Stored |
|---|---|
| `free` | `free` |
| `proLifetime` | `pro-lifetime` |
| `proSubscription` | `pro-subscription` |

Never the index. Reordering the enum must not silently promote a free user
to Pro or the reverse.

The spelling is **not a local choice**: `schemas/entitlement/v1` in
`lumbrecode-engineering`, synchronized into `.lumbrecode/`, is the vocabulary
every LumbreCode app writes on every stack. A Flutter app and a web app
belonging to one product must agree on how "lifetime Pro" is spelled.

Template 3.2.1 wrote `pro_lifetime`; that form still decodes, because
dropping it would downgrade a paying user to `free` — the one direction this
cache must never fail in.

### Fail-safe decoding

`Entitlement.fromStored` maps anything unrecognized to `free`. That is the
correct direction for a **cache of a paid state**: the store can re-grant a
lost entitlement on the next restore, while a wrongly granted one cannot be
taken back without an angry user.

### `checkedAt`

Written only together with a store-verified entitlement (IAP-014). Its
absence means "never verified", which is the truth for the whole template —
no store call has ever succeeded, because there is no store adapter.

Stored in UTC. A local timestamp would shift meaning when the device travels.

## The gateway interface

```dart
abstract interface class PurchaseGateway {
  Future<bool> isStoreAvailable();
  Future<Entitlement> restorePurchases();
}
```

Two calls, both user-triggered. No stream, no listener, no pending-purchase
queue — those arrive with real purchases and would be unused surface today.

## What the template does not persist

- No product identifiers, prices or localized store metadata. All of it is
  store-owned and can change without an app release; caching it would create
  a second source of truth for something the app does not control.
- No receipt, token or transaction identifier. Those are credentials, and the
  template has no server to verify them against.
- No purchase history.

## Relationship to the destructive actions

| Action | `billing.*` |
|---|---|
| Delete app data (spec 0005) | untouched — entitlement is not content |
| Reset settings (spec 0005) | removed, so the next start reads `free` |

Removing the cache is safe by construction: it is a cache, and a restore
re-establishes it.
