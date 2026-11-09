import 'package:flutter_test/flutter_test.dart';

import '../../support/package_encapsulation.dart';

/// Guards ADR-0015: the template ships the purchase **seam**, never a
/// billing plugin.
///
/// A rule in a document erodes. One "quick" import of `in_app_purchase` into
/// a widget is invisible in review, and by the time an app needs to replace
/// or remove it, the plugin's types are in thirty files — plus its platform
/// manifests and store declarations, which every derived app then inherits
/// whether it sells anything or not (KI-009 records what that costs).
///
/// When an app does add billing, the adapter is the single permitted import
/// site, and this test becomes a normal encapsulation test pointing at it:
///
/// ```dart
/// expectPackageEncapsulated(
///   package: 'in_app_purchase',
///   allowedDirectory: 'lib/features/monetization/data',
/// );
/// ```
void main() {
  const billingPackages = [
    'in_app_purchase',
    'in_app_purchase_android',
    'in_app_purchase_storekit',
    'purchases_flutter',
  ];

  for (final package in billingPackages) {
    test('package:$package is not imported anywhere', () {
      // No allowed directory at all: the template has no adapter, because it
      // has no billing dependency (spec 0007, IAP-001).
      final offenders = findPackageImportsOutside(
        package: package,
        allowedDirectory: '',
      );

      expect(
        offenders,
        isEmpty,
        reason:
            'ADR-0015: the template ships PurchaseGateway and no billing '
            'plugin. If this app now sells something, add the adapter under '
            'lib/features/monetization/data/ and point this test at it '
            'instead of deleting it:\n  ${offenders.join('\n  ')}',
      );
    });
  }
}
