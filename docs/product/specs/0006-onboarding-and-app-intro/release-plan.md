# Release plan: App intro (onboarding)

Target release **3.2.1**. Slice 5 of
`docs/delivery/implementation-plans/0002-settings-and-app-shell.md`.

## Single phase

The intro is small enough to land in one slice, but it must land **after**
the settings hub (spec 0005, phase 2): the replay row lives on the hub, and
the routing change that removes the settings page from the startup path is
what makes room for the intro.

Order inside the slice:

1. `app.onboardingCompleted` in the register, with its unit tests. Nothing
   reads it yet.
2. The notifier, reading and writing through the register.
3. The pager, tested standalone with injected callbacks — no `ProviderScope`
   needed, same pattern as the settings page.
4. The routing branch at the end of the splash, plus the harness flag that
   lets existing tests skip the intro.
5. The replay row on the hub.

**Done when:** the routing tests cover all three destinations (recovery,
intro, greeting), the pager's skip and finish paths both persist the flag, a
failing store still lets the user out, and the accessibility checks pass.

## Test-harness change

`TestAppHarness` seeds `app.onboardingCompleted = true` by default, so every
existing test still lands on the app rather than in the intro. A named
parameter turns that off for the first-start tests.

This is deliberately the default: the alternative — every existing test
learning to dismiss an intro — would make the intro a fixture of the whole
suite instead of a subject of a few tests.

## Rollout note for derived apps

An app already built on template 3.0.0 has no stored flag, so it shows the
intro once after upgrading. That is the intended behaviour for new content.
An app that does not want it deletes `features/onboarding/`, the route and
the register entry — the routing branch then falls through to the app.
