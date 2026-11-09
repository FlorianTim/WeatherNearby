# Acceptance criteria: App intro (onboarding)

## Routing

- [ ] With no stored flag, the app reaches the intro after the splash and not
      the greeting. (ONB-001)
- [ ] With the flag stored as `true`, the app reaches the greeting directly.
      (ONB-002)
- [ ] With a fatal startup failure **and** no stored flag, the app reaches the
      recovery screen. (ONB-003)
- [ ] No intermediate loading screen appears between splash and intro.
      (ONB-004)
- [ ] The settings row opens the intro even though the flag is `true`.
      (ONB-005)

## Flow

- [ ] Tapping the primary action advances one page; the indicator follows.
      (ONB-022, ONB-024)
- [ ] Swiping advances one page; the primary action label updates on the last
      page. (ONB-023, ONB-024)
- [ ] "Skip" on page one leaves the intro immediately. (ONB-020)
- [ ] The last page's primary action leaves the intro. (ONB-021)

## The settings page inside the intro

- [ ] Tapping "English" switches the intro's own strings to English.
      (ONB-012)
- [ ] Tapping "Dunkel" switches the intro to the dark theme. (ONB-012)
- [ ] The choice survives leaving the intro — the greeting is in the chosen
      language. (ONB-011)

## Persistence

- [ ] Finishing writes `app.onboardingCompleted = true`. (ONB-030)
- [ ] Skipping writes the same value. (ONB-020, ONB-030)
- [ ] With a key-value store whose write throws, the user still leaves the
      intro and no error surfaces to the framework. (ONB-031)
- [ ] Reopening from settings and finishing again leaves language, theme and
      content untouched. (ONB-032)
- [ ] After "Reset settings", the next start shows the intro. (ONB-033)

## Permissions

- [ ] A test asserts that no permission gateway is called anywhere in the
      intro flow, including on the last page. (ONB-013)

## Accessibility

- [ ] Skip and the primary action are at least 48 dp tall. (ONB-040)
- [ ] The page renders without overflow at `TextScaler.linear(2.0)` on a
      phone-sized surface. (ONB-014)
- [ ] The page indicator produces no semantics node of its own. (ONB-041)
