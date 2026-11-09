# api_client

HTTP client scaffold for talking to the app's backend.

**Classification: optional — removable when `backend_enabled: false`.**

Nothing in the template app depends on this package. When the app spec sets
`backend_enabled: false`, the template initializer may delete this package
(and its entry in the root `pubspec.yaml` workspace list) instead of
carrying dead scaffolding:

```bash
./scripts/remove_backend.sh --with-packages
```
