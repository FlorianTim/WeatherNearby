// Entry point of the drift web worker.
//
// This file is NOT part of the app: it is compiled on its own to
// `web/drift_worker.js` by `tool/sync_web_database_assets.dart`. Drift's
// `WasmDatabase` starts that script as a shared/dedicated web worker and
// talks to it over `postMessage`, which is what keeps sqlite3 off the UI
// isolate on the web.
//
// It must be compiled with the same drift version the app depends on —
// worker and client speak a versioned protocol.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
