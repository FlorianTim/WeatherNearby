import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/storage/key_value_store.dart';

part 'onboarding_notifier.g.dart';

/// Whether the first-start intro has been finished or skipped.
///
/// Read **synchronously**: `bootstrap()` has already installed the
/// persistent key-value store by the time the splash finishes, so the
/// routing decision at the end of the splash needs no `await` and no
/// intermediate loading screen (spec 0006, ONB-004).
///
/// The definition lives in [AppSettings.onboardingCompleted] — key, default
/// and encoding are declared once, there.
@Riverpod(keepAlive: true)
class OnboardingCompleted extends _$OnboardingCompleted {
  @override
  bool build() =>
      AppSettings.onboardingCompleted.read(ref.watch(keyValueStoreProvider));

  /// Records that the user finished or skipped the intro.
  ///
  /// A failed write is **swallowed on purpose**: a storage failure must
  /// never be able to trap someone inside a modal flow (ONB-031). The state
  /// moves on regardless, so the user leaves; the worst case is that the
  /// intro appears once more on the next start, which is recoverable.
  Future<void> complete() async {
    state = true;
    try {
      await AppSettings.onboardingCompleted.write(
        ref.read(keyValueStoreProvider),
        true,
      );
    } catch (_) {
      // Intentionally ignored — see above.
    }
  }
}
