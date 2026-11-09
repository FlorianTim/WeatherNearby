import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app_core/app_core.dart';

import '../core/errors/last_error_buffer.dart';
import '../core/storage/key_value_store.dart';
import 'app.dart';

Future<void> bootstrap() async {
  final errorBuffer = LastErrorBuffer();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework errors: keep the default reporting, additionally record the
      // error so a later feedback mail can attach it.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        errorBuffer.add(
          AppError(
            error: details.exception,
            stackTrace: details.stack,
            source: 'flutter',
          ),
        );
      };

      // The flavor names its own keys, so a snapshot installed next to the
      // release never reads its settings (AppFlavor.preferencePrefix).
      final prefix = AppFlavor.current.preferencePrefix;
      final persistent = await SharedPreferencesKeyValueStore.create();
      final KeyValueStore keyValueStore = prefix.isEmpty
          ? persistent
          : PrefixedKeyValueStore(persistent, prefix);

      runApp(
        App(
          overrides: [
            keyValueStoreProvider.overrideWithValue(keyValueStore),
            lastErrorBufferProvider.overrideWithValue(errorBuffer),
          ],
        ),
      );
    },
    (error, stackTrace) {
      // Uncaught async errors outside the framework.
      errorBuffer.add(
        AppError(error: error, stackTrace: stackTrace, source: 'zone'),
      );
      debugPrint('Uncaught zone error: $error\n$stackTrace');
    },
  );
}
