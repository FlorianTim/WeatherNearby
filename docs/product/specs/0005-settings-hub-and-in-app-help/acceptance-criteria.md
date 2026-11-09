# Acceptance criteria: Settings hub, in-app help and privacy page

Each criterion is a test. `T-` ids are registered in
`docs/testing/` alongside the existing template test plan.

## Hub

- [ ] The settings page renders without a "Continue" button and without any
      wizard affordance. (SET-002)
- [ ] Language and appearance are changeable directly on the hub; tapping
      "English" switches the app language without navigation. (SET-003, SET-010)
- [ ] Every navigation row opens its page and returns with system back.
      (SET-004)
- [ ] Section headings appear in the specified order. (SET-005)
- [ ] "Report the last error" is absent when no error is buffered, and
      present after one was recorded. (SET-041, SET-006)
- [ ] In a release build the development section is absent. Asserted by a
      test that pumps the hub with the release flag simulated. (SET-051)

## Help

- [ ] Opening "Anleitung" with app language `de` loads
      `assets/help/manual_de.md` and renders its headings and lists. (SET-020)
- [ ] The same page with app language `en` loads `manual_en.md`. (SET-021)
- [ ] An app language that has no asset variant loads the `_en` file. (SET-022)
- [ ] A missing asset renders the localized load-error text and no exception
      reaches the framework. (SET-023)
- [ ] Tapping an `https` link inside a document calls the launcher seam with
      that URI. (SET-024)
- [ ] A `javascript:` link inside a document is refused by the seam and the
      refusal is reported to the user. (SET-024)

## Privacy and data

- [ ] The page states local storage in the app language. (SET-030)
- [ ] With an empty permission list, no permission section renders. (SET-032)
- [ ] With two declared permissions, both render with their state. (SET-031)
- [ ] The privacy-policy and data-deletion rows open the URLs derived from
      `AppIdentity.links`. (SET-033)
- [ ] The privacy-contact row opens a `mailto:` URI addressed to the privacy
      mailbox, whose body contains the app version and no device identifier.
      (SET-034)
- [ ] "Delete app data" shows a confirmation naming the consequence;
      cancelling changes nothing. (SET-038)
- [ ] Confirming it empties the content tables and leaves the stored language
      and theme untouched. (SET-036)
- [ ] "Reset settings" shows its own confirmation, and confirming returns
      language and theme to "follow the device" while content survives.
      (SET-037)
- [ ] Both actions show a confirmation message afterwards. (SET-039)

## Diagnostics

- [ ] The diagnostics page lists one row per entry of `AppSettings.all`.
      (SET-050)
- [ ] A setting that has never been written shows its default and is marked
      as unset. (SET-050)
- [ ] The page offers no way to change a value. (SET-052)

## Shared widgets

- [ ] `AppOptionTile` renders selected state with both a radio icon and a
      container colour. (SET-012, SET-060)
- [ ] `AppSettingsSection` renders nothing when given no children. (SET-006)
- [ ] Every row on the hub is at least 48 dp tall. (accessibility rule 1)
- [ ] The hub renders without overflow at `TextScaler.linear(2.0)`.
      (SET-062)
