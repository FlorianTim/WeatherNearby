# Open questions: In-app purchase placeholder

## Resolved during specification

### Q1 — Ship `in_app_purchase`, or ship only the seam?

**Decided: only the seam** (ADR-0015). A template dependency is paid for by
every derived app, whether it sells anything or not — in resolution
constraints, in platform setup, and in store declarations. The seam plus a
recipe gives an app that *does* sell something a one-file change, and gives
every other app nothing to delete.

### Q2 — Where does the entitlement cache live: settings or database?

**Decided: the settings register.** It is a single small value, it must be
readable synchronously at startup, and it must survive "delete app data"
(which clears content, not settings). All three point at the key-value store.

### Q3 — Does `restorePurchases()` belong in the interface today, with no store?

**Yes.** It is the one call a user expects to find even before anything is
for sale ("I paid on my old phone"), and its store-less answer is honest and
testable. Leaving it out would mean changing the interface — and every fake —
in the change that adds billing.

### Q4 — Should the reference app gate one feature behind Pro, as a demo?

**No** (IAP-022). The reference app is the template's proving ground, and a
gated demo feature would teach every derived app that the feature is paid.
The gating mechanism is proven by tests with a test-only catalogue instead.

## Still open

### Q5 — Does the entitlement need a verification interval?

Once purchases exist, a cached Pro entitlement should probably be re-verified
periodically — `billing.checkedAt` is stored precisely so that becomes
possible. What the interval is, what happens when verification fails offline,
and whether a grace period applies are all questions that need a real product
decision.

**Proposal:** decide with the first app that sells something. The key is in
place; the policy is not.

### Q6 — One gateway, or one per platform store?

Android and iOS differ enough in restore semantics that a single interface
may end up with platform-conditional behaviour inside the adapter.

**Proposal:** keep one interface. Revisit only if the adapter's platform
branches outgrow it — which is a signal the interface is wrong, not that a
second one is needed.
