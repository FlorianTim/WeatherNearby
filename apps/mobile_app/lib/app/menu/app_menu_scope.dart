import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/menu/app_menu_host.dart';
import 'app_menu_commands.dart';
import 'app_menus.dart';

/// The menu bar of the app around [child]: built from the current route, so
/// the entries that leave a screen can be disabled while the splash runs, and
/// wired to the router.
///
/// Placed in `MaterialApp.router`'s `builder`, which sits above the Navigator.
class AppMenuScope extends StatefulWidget {
  const AppMenuScope({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<AppMenuScope> createState() => _AppMenuScopeState();
}

class _AppMenuScopeState extends State<AppMenuScope> {
  late String _location = _read();

  String _read() => widget.router.routeInformationProvider.value.uri.toString();

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(AppMenuScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
      _location = _read();
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  /// The router notifies while it builds a page; a `setState` then is an
  /// error, so the rebuild waits for the end of the frame.
  void _onRouteChanged() {
    final next = _read();
    if (next == _location) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _location = _read());
      });
    } else {
      setState(() => _location = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppMenuHost(
      semanticLabel: l10n.menuLabel,
      menus: buildAppMenus(
        l10n,
        location: _location,
        desktop: isDesktopPlatform,
        mac: defaultTargetPlatform == TargetPlatform.macOS,
      ),
      onCommand: (id) => runAppMenuCommand(id, widget.router),
      child: widget.child,
    );
  }
}
