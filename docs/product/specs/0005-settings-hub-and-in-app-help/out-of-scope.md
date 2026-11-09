# Out of scope: Settings hub, in-app help and privacy page

## Not in 3.2.1

| Excluded | Why |
|---|---|
| **Search inside the help documents** | A template manual short enough to be useful does not need it. Revisit when a real app's manual passes a few screens. |
| **Screenshots in help documents** | Screenshots have to be produced by an integration-test pipeline to stay current; a hand-placed one is stale within a release. The renderer ignores images by contract. |
| **Backup / export / restore** | A file format is a compatibility promise and needs its own spec. Named as a 3.2+ candidate in `0001-todo-reference-app.md`. |
| **Editing settings from the diagnostics page** | Diagnostics is read-only by requirement (SET-052). A writable debug console is a different feature with different risks. |
| **A concrete `PermissionGateway`** | The permission overview renders what it is given. The first real implementation arrives with spec 0003 (reminders). |
| **Per-feature settings of the reference app** | Reminder lead time, completed-task visibility and similar belong to specs 0001–0003. |
| **Account, sync or profile rows** | The template has no account. Adding a placeholder would suggest a backend that does not exist. |
| **Notification settings** | Nothing schedules a notification yet (spec 0003). A switch that controls nothing is worse than no switch. |
| **Theming beyond light/dark** | Accent colour, dynamic colour and font scaling are design-system decisions, not settings decisions. |
| **An in-app licence text for the help documents** | The offline licence page on the About page already covers dependencies. |

## Deliberately kept as it is

- **The About page.** External links, support mailboxes, offline licences and
  the version footer already work and are already tested. The hub links to
  it; nothing is copied out of it.
- **`wipeAllData()`.** Its transactional, children-before-parents behaviour
  is unchanged. Only its entry point moves to the privacy page.
- **The online FAQ link.** The bundled FAQ does not replace it — one is the
  offline version, the other is the one that can be corrected without a
  release.
