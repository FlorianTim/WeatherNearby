import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../application/monetization_providers.dart';

/// Entitlement status.
///
/// Shows a state and sells nothing: no price, no product list, no buy
/// action, no comparison table (IAP-033). Every one of those is a
/// store-review surface that must not exist before it works, and the
/// template has no store account to make it work against (ADR-0015).
class ProPage extends ConsumerStatefulWidget {
  const ProPage({super.key});

  @override
  ConsumerState<ProPage> createState() => _ProPageState();
}

class _ProPageState extends ConsumerState<ProPage> {
  bool _restoring = false;

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _restoring = true);
    try {
      final restored = await ref
          .read(purchaseGatewayProvider)
          .restorePurchases();

      if (restored.isPro) {
        await ref
            .read(cachedEntitlementProvider.notifier)
            .setVerified(restored);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            restored.isPro ? l10n.proRestoreRestored : l10n.proRestoreNone,
          ),
        ),
      );
    } catch (_) {
      // A missing platform channel or absent store services is an expected
      // answer here, not a crash: report it and leave the cache alone.
      messenger.showSnackBar(SnackBar(content: Text(l10n.proRestoreFailed)));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entitlement = ref.watch(cachedEntitlementProvider);
    final storeAvailable = ref.watch(storeAvailableProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(
                entitlement.isPro ? l10n.proStatusPro : l10n.proStatusFree,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(l10n.proAllFree),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              // Three distinct states. Without the pending one, a slow
              // platform call is indistinguishable from an unavailable
              // store — and the first support question about billing is
              // always "it says unavailable, is that a bug?".
              title: Text(switch (storeAvailable) {
                AsyncData(:final value) =>
                  value ? l10n.proStoreAvailable : l10n.proStoreUnavailable,
                AsyncError() => l10n.proStoreUnavailable,
                _ => l10n.proStoreChecking,
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _restoring ? null : _restore,
              child: _restoring
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.proRestore),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.proNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
