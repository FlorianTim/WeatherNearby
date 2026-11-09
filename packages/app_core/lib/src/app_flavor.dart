/// The stream a build belongs to.
///
/// - [dev] — `flutter run` and debug builds; developer tools, sample data.
/// - [snapshot] — a build of any branch, for trying things out; behaves like
///   [dev] but is installed like an app.
/// - [staging] — a build against a staging backend (`API_BASE_URL`).
/// - [prerelease] — a release candidate, tested before it is released;
///   behaves like [prod].
/// - [prod] — the finished application, and every release-mode build that
///   names nothing.
///
/// The build names its flavor with `--dart-define=APP_FLAVOR=<name>`. Every
/// place that behaves differently asks this type, so there is one switch to
/// read and test.
///
/// Each flavor except [dev] and [prod] keeps its data under its own names
/// (see [storageSuffix]) so a snapshot or a candidate never writes into the
/// documents of the release, even where both are installed side by side.
enum AppFlavor {
  dev,
  snapshot,
  staging,
  prerelease,
  prod;

  /// The flavor for [value], or [dev] when it names none.
  ///
  /// Kept for callers that parse a stored or typed value. A **build** should
  /// ask [resolve], which falls back to [prod] in a release-mode build.
  static AppFlavor fromString(String value) => _byName(value) ?? AppFlavor.dev;

  /// The flavor of a build: the named one, else [dev] for a debug build and
  /// [prod] for a release-mode build.
  ///
  /// A release build that forgot its define must not show developer tools, so
  /// the fallback depends on the build mode, not on a constant.
  static AppFlavor resolve({required bool isProduct, String? named}) =>
      _byName(named) ?? (isProduct ? AppFlavor.prod : AppFlavor.dev);

  /// The flavor of this build, from `APP_FLAVOR` and the build mode.
  static final AppFlavor current = resolve(
    isProduct: const bool.fromEnvironment('dart.vm.product'),
    named: const String.fromEnvironment('APP_FLAVOR'),
  );

  static AppFlavor? _byName(String? value) {
    final name = value?.trim().toLowerCase();
    if (name == null || name.isEmpty) return null;
    for (final flavor in AppFlavor.values) {
      if (flavor.name == name) return flavor;
    }
    return null;
  }

  /// Developer tools and sample data: [dev] and [snapshot].
  bool get showsDeveloperTools =>
      this == AppFlavor.dev || this == AppFlavor.snapshot;

  /// Whether the build says what it is: every flavor but the release.
  bool get isRelease => this == AppFlavor.prod;

  /// What the data is named with: nothing for [prod] and [dev], else the
  /// flavor's name. [dev] keeps the plain names because a debug build is
  /// installed by the developer's tooling over the previous debug build.
  String get storageSuffix =>
      (this == AppFlavor.prod || this == AppFlavor.dev) ? '' : name;

  /// A database or file name for this flavor: `app_database` for [prod],
  /// `app_database_snapshot` for [snapshot].
  String databaseName(String base) =>
      storageSuffix.isEmpty ? base : '${base}_$storageSuffix';

  /// A prefix for preference keys, `''` for [prod] and [dev], else
  /// `snapshot.`. Preferences live in one file per app on desktop, where the
  /// flavors would otherwise read each other's settings.
  String get preferencePrefix => storageSuffix.isEmpty ? '' : '$storageSuffix.';
}
