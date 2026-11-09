# ADR-0015: The in-app purchase seam ships without a billing dependency

## Status

accepted

## Date

2026-08-26

## Decision owners

- Product Owner (F. Kroschewski)
- Template architecture

## Related feature / spec

- `docs/product/specs/0007-in-app-purchase-placeholder/`
- Slice 6 of `docs/delivery/implementation-plans/0002-settings-and-app-shell.md`
- `docs/architecture/contracts/06-library-evaluation.md`
- `docs/architecture/patterns/platform-gateways.md`
- `docs/known-issues.md` — KI-009

## Related issues / PRs

- none yet

## Context

`packages/feature_flags` ships `Entitlement` and `FeatureGates` — the
decision half of monetization — and nothing supplies them. The reference
app *WasThereSomething* has the other half: a `PurchaseGateway` interface, an
`in_app_purchase` adapter behind it, a cached entitlement, and a Pro page.

Adopting it raises one question: does the template take the dependency too?

Three facts bear on it.

1. **A template dependency is paid for by every derived app**, not only by
   the ones that use it. It appears in resolution, in the platform manifests,
   in the store declarations a reviewer checks, and in every future upgrade's
   constraint solve.

2. **KI-009 is exactly this failure, already recorded.** In the reference
   app, `device_calendar` — a plugin one feature needed — blocked the upgrade
   of a completely unrelated UI package. A billing plugin is a bigger version
   of that plugin.

3. **The part that is hard to add later is not the plugin.** It is the
   *shape*: an interface app code can depend on, a cache that degrades
   safely, and a single question (`featureUnlocked(key)`) that call sites
   ask. An app that skipped the shape and imported the plugin into a widget
   cannot retrofit it without touching every call site.

## Decision

**The template ships the whole monetization shape and none of the billing
plugin.**

Concretely:

- `PurchaseGateway` — the interface, in the app, with exactly the two calls a
  user can trigger: `isStoreAvailable()` and `restorePurchases()`.
- `UnavailablePurchaseGateway` — the default. Not a stub: it is the correct
  implementation for a device with no store and for web, and it is what the
  template runs.
- `FakePurchaseGateway` — deterministic, including a failure mode, for tests.
- The entitlement cache in the settings register, decoding fail-safe to
  `free`.
- A Pro page that shows the real state and sells nothing.
- `docs/architecture/patterns/in-app-purchase-gateway.md` — the recipe for
  the concrete adapter: dependency, code, platform setup, store
  declarations, tests.

This follows the rule the 3.0.0 adoption already set for capability modules:
**what needs no new dependency becomes template code; what drags in a plugin,
a manifest entry or a store declaration becomes a recipe.**

An encapsulation test asserts that no source file in the workspace imports a
billing package, so the decision cannot erode quietly.

## Alternatives considered

### A. Ship `in_app_purchase` in the template

Rejected. Every derived app inherits a billing dependency it must either use
or delete, plus the platform setup that comes with it. KI-009 records the
cost of exactly this in the reference app, on a smaller plugin.

### B. Ship nothing — let each app build monetization from scratch

Rejected. This is the status quo, and it produces the failure the template
exists to prevent: the first app in a hurry imports the plugin directly into
a widget, and the coupling is then unfixable without touching every call
site.

### C. A separate `packages/monetization` package with the plugin

Rejected for now. A workspace package is still resolved by the workspace, so
the constraint problem does not go away — it only moves. It becomes the right
answer once two apps sell something and share a real adapter.

### D. Ship the interface but no page

Rejected. Without the page the interface has no consumer, so nothing proves
it is usable, and the settings hub has nothing to link — which is how an
unused interface drifts out of shape before its first real use.

## Consequences

### Positive

- No derived app inherits a billing dependency it did not ask for.
- The expensive part — the shape — exists on day one and is tested.
- Adding real billing is a bounded change: one dependency, one adapter file,
  one provider override, no call-site changes.
- The template can be built and tested on web and on CI without any store.

### Negative

- The template cannot demonstrate a real purchase end to end. Accepted: a
  demonstration needs a configured store account, which a template cannot
  have.
- The recipe can go stale relative to the plugin's API. Mitigated by keeping
  the recipe's adapter small enough to re-verify quickly, and by pinning it
  to the interface the template owns rather than to the plugin's surface.
- Two places to look when adding billing (the code and the recipe). Accepted;
  the alternative is a dependency in every app.

### Neutral

- `FeatureGates` stays fail-open and its catalogue stays empty. The template
  gates nothing, so no reference-app feature teaches derived apps that it is
  paid.

## Test and validation impact

- Encapsulation test: no billing package is imported anywhere.
- Unit tests for the cache's fail-safe decoding, including a literal table
  pinning each enum's stored value against reordering.
- Widget tests for the Pro page in all three store states and both restore
  outcomes.
- A test asserting that store availability is never queried during startup.
