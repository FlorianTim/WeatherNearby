import 'package:app_core/app_core.dart';
import 'package:flutter/foundation.dart';

/// Whether developer tools — the settings diagnostics — are reachable.
///
/// Every debug build, and the release-mode builds of the `snapshot` flavor,
/// which exist to be tried out. A `prerelease` or `prod` build never shows
/// them: its route is not registered at all, so a deep link cannot reach it
/// (SET-051).
bool get developerToolsEnabled =>
    !kReleaseMode || AppFlavor.current.showsDeveloperTools;
