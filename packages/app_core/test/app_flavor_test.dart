import 'package:app_core/app_core.dart';
import 'package:test/test.dart';

void main() {
  group('AppFlavor', () {
    test('fromString returns the named flavor', () {
      for (final flavor in AppFlavor.values) {
        expect(AppFlavor.fromString(flavor.name), equals(flavor));
      }
    });

    test('fromString defaults to dev for unknown value', () {
      expect(AppFlavor.fromString('unknown'), equals(AppFlavor.dev));
    });

    test('resolve takes the named flavor, whatever the build mode', () {
      expect(
        AppFlavor.resolve(isProduct: true, named: 'snapshot'),
        equals(AppFlavor.snapshot),
      );
      expect(
        AppFlavor.resolve(isProduct: false, named: ' Prerelease '),
        equals(AppFlavor.prerelease),
      );
    });

    test('resolve falls back to dev in debug and prod in a release build', () {
      expect(AppFlavor.resolve(isProduct: false), equals(AppFlavor.dev));
      expect(AppFlavor.resolve(isProduct: true), equals(AppFlavor.prod));
      expect(
        AppFlavor.resolve(isProduct: true, named: 'nightly'),
        equals(AppFlavor.prod),
      );
      expect(
        AppFlavor.resolve(isProduct: true, named: ''),
        equals(AppFlavor.prod),
      );
    });

    test('only dev and snapshot show developer tools', () {
      expect(
        AppFlavor.values.where((f) => f.showsDeveloperTools).toList(),
        equals([AppFlavor.dev, AppFlavor.snapshot]),
      );
    });

    test('data names: release and dev keep the plain ones, others apart', () {
      expect(AppFlavor.prod.databaseName('app_database'), 'app_database');
      expect(AppFlavor.dev.databaseName('app_database'), 'app_database');
      expect(
        AppFlavor.snapshot.databaseName('app_database'),
        'app_database_snapshot',
      );
      expect(
        AppFlavor.prerelease.databaseName('app_database'),
        'app_database_prerelease',
      );
      expect(AppFlavor.prod.preferencePrefix, '');
      expect(AppFlavor.snapshot.preferencePrefix, 'snapshot.');
    });

    test('every flavor but prod is not a release', () {
      expect(AppFlavor.prod.isRelease, isTrue);
      expect(AppFlavor.prerelease.isRelease, isFalse);
    });
  });
}
