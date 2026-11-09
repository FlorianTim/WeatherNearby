# shared_models

Data models shared between the Flutter app and the Dart backend
(`services/api`).

**Classification: optional — removable when `backend_enabled: false`.**

Nothing in the template app depends on this package; its only consumer is
`services/api`. A model that lives purely in the app belongs in that feature's
`domain/`, not here — this package exists so that the *same* type can be
serialised on both sides of an HTTP boundary.

When the app spec sets `backend_enabled: false`, the removal tool deletes this
package together with the backend:

```bash
./scripts/remove_backend.sh --with-packages
```

Without `--with-packages` the backend goes but this package stays, which
leaves it genuinely dead — so pass the flag unless you are about to add your
own backend.
