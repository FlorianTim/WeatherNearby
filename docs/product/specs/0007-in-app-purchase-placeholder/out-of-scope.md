# Out of scope: In-app purchase placeholder

| Excluded | Why |
|---|---|
| **The `in_app_purchase` dependency** | ADR-0015. Every derived app would inherit a billing plugin, its manifests, its store declarations and its version constraints — and KI-009 records what one unnecessary plugin can do to an unrelated upgrade. |
| **Products, prices, a buy flow** | Needs real store configuration, real product ids, and a store review. Nothing can be tested against a store that does not exist. |
| **Subscription management, renewal, grace periods** | Platform-specific state machines. They belong to the app that actually sells a subscription. |
| **Receipt or server-side validation** | Requires a backend the template does not have. A client-only "validation" would be security theatre. |
| **A paywall screen** | A paywall is a design and pricing decision per app, not a template surface. |
| **Promo codes, trials, introductory offers** | Store features with per-platform rules; each is its own spec. |
| **Gating an actual template feature** | The catalogue ships empty by requirement (IAP-022). Gating something in the reference app would make the demo teach that the feature is paid. |
| **A purchase stream / pending-purchase queue** | Only meaningful once purchases exist. Adding it now would ship untested, unused surface that the real adapter would then have to match. |
| **Telemetry on conversion** | The template has no telemetry. |

## What "placeholder" means here

It does **not** mean a stub that throws or a screen with lorem ipsum.
Everything shipped works and is tested:

- the interface is the real interface the adapter will implement,
- the default gateway is a legitimate implementation for a device with no
  store (and for web),
- the cache round-trips and degrades correctly,
- the page shows the real state.

What is missing is only the part that requires a store account.
