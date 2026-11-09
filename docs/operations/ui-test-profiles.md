# UI test profiles

Use `test/support/ui_test_profile.dart` for explicit logical dimensions and
text scaling. Standard phone: 390x844/1x; compact phone: 360x800/1x;
large text: 390x844/2x; tablet: 1024x768/1x; desktop: 1440x900/1x.
DPR changes capture resolution, not layout dimensions.

Functional tests normally use standard phone. Retain one focused 2x check
per main screen and relevant critical dialogs (contract 07). Test primary
actions remain reachable, not just that a page builds. Use representative
locale/theme cases rather than multiplying every dimension everywhere.
Keep specific minimum-width and known regression cases with their rationale.

Scroll to offscreen actions and assert their hit area before tapping. Tall
surfaces are allowed for labelled whole-content ordering/semantics inspections;
they do not establish phone usability. Never replace lazy production lists
to make tests easier. Keep callbacks and behavioral assertions intact.

Screenshots explicitly use 1x text by default and restore overrides. Special
text profiles need distinct names. Report standard behavior first, then
focused large-text coverage. Widget checks do not establish device acceptance.

Measure warm-up plus three comparable runs before claiming runtime savings.
Separate SDK startup, compilation and test execution. Run focused tests while
editing and the full suite after integration; no automatic new opt-in gates.
