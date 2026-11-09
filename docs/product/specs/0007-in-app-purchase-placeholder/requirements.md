# Requirements: In-app purchase placeholder

Prefix `IAP-`.

## The gateway

| ID | Requirement |
|---|---|
| IAP-001 | App code MUST NOT import a billing package directly. The only permitted consumer is the gateway adapter. |
| IAP-002 | The template MUST ship `PurchaseGateway` as an interface with `isStoreAvailable()` and `restorePurchases()`. |
| IAP-003 | The default implementation MUST report no store and no entitlement, and MUST NOT throw on any platform, including web. |
| IAP-004 | A deterministic fake MUST exist for tests, configurable per outcome including failure. |
| IAP-005 | `isStoreAvailable()` MUST be called only on explicit user action — never during startup. |
| IAP-006 | A gateway call that throws MUST degrade to "unavailable", never to an unhandled error. |

## The entitlement cache

| ID | Requirement |
|---|---|
| IAP-010 | The current entitlement MUST be cached in the settings register under `billing.entitlement`. |
| IAP-011 | An unknown, empty or corrupted stored value MUST decode to `Entitlement.free`. |
| IAP-012 | The stored form MUST be the stable string of the enum, never its index. |
| IAP-013 | The timestamp of the last store verification MUST be stored under `billing.checkedAt` as UTC ISO-8601, and MUST be `null` while no verification has happened. |
| IAP-014 | Writing a verified entitlement MUST write both keys together. |
| IAP-015 | The cache is a cache: the store is the source of truth once purchases exist, and nothing in the app may treat the cached value as proof of payment. |

## Gating

| ID | Requirement |
|---|---|
| IAP-020 | App code MUST ask one question — is this feature key unlocked — and MUST NOT branch on the entitlement enum directly. |
| IAP-021 | An unknown feature key MUST be unlocked (fail-open). A typo must never lock a user out. |
| IAP-022 | The shipped gate catalogue MUST be empty, so the template gates nothing. |

## The Pro page

| ID | Requirement |
|---|---|
| IAP-030 | The page MUST show the current entitlement in words. |
| IAP-031 | The page MUST state that all features are currently free. |
| IAP-032 | The page MUST show store availability, with a distinct state while the answer is still being fetched. |
| IAP-033 | The page MUST NOT show prices, product lists or a buy action while no purchase exists. |
| IAP-034 | A restore action MUST exist, MUST report its outcome, and MUST NOT change the cached entitlement when the store is unavailable. |
| IAP-035 | The page MUST be reachable from the settings hub, and the hub row MUST NOT read as a locked feature. |

## Documentation

| ID | Requirement |
|---|---|
| IAP-040 | A recipe MUST document the concrete billing adapter: dependency, adapter code, platform setup, store declarations and the tests to add. |
| IAP-041 | The recipe MUST state what changes and what does not when the adapter is added — exactly one provider override, no call-site change. |
