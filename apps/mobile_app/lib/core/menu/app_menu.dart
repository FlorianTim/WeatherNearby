import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

/// One entry of a menu.
///
/// A menu is **data**: groups of items and a handler that receives the id of
/// the chosen item. [AppMenuHost] draws that data — as the operating system's
/// own menu bar on macOS, as a Flutter menu bar on Windows, Linux and the web
/// — so the entries, their labels and their keys have one definition and the
/// renderers cannot drift apart.
@immutable
class AppMenuItem {
  const AppMenuItem({
    required this.id,
    required this.label,
    this.shortcut,
    this.enabled = true,
    this.dividerBefore = false,
  });

  /// Stable id the handler receives, e.g. `goto:settings`.
  final String id;

  final String label;

  /// The key that runs this entry from anywhere in the app.
  final SingleActivator? shortcut;

  final bool enabled;

  /// Whether a separator is drawn before this entry.
  final bool dividerBefore;
}

/// One menu of the bar.
@immutable
class AppMenuGroup {
  const AppMenuGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<AppMenuItem> items;
}

/// Runs the command behind a menu item.
typedef AppMenuCommandHandler = FutureOr<void> Function(String id);

/// How the menu is drawn on this platform.
enum AppMenuStyle {
  /// The operating system's menu bar (`PlatformMenuBar`): macOS.
  native,

  /// A menu bar drawn by Flutter at the top of the window: Windows, Linux and
  /// the web. Flutter has no native menu on these platforms.
  bar,

  /// No bar — a phone or a tablet; the shortcuts still work on a hardware
  /// keyboard.
  none;

  /// The style for the running platform.
  static AppMenuStyle detect() {
    if (kIsWeb) return AppMenuStyle.bar;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => AppMenuStyle.native,
      TargetPlatform.windows || TargetPlatform.linux => AppMenuStyle.bar,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => AppMenuStyle.none,
    };
  }
}
