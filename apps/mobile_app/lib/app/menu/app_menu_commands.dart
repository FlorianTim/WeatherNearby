import 'dart:ui' show AppExitType;

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app_menus.dart';

/// Runs the command behind a menu entry.
///
/// The menu only names what the user chose; this is where it becomes a route
/// change or the end of the application. Unknown ids are ignored: a menu entry
/// that arrives from a newer definition must never crash an older handler.
Future<void> runAppMenuCommand(String id, GoRouter router) async {
  final goto = gotoRouteOf(id);
  if (goto != null) {
    router.go(goto);
    return;
  }
  final help = helpRouteOf(id);
  if (help != null) {
    await router.push(help);
    return;
  }
  if (id == quitMenuId) {
    // Every write is already in the database; nothing is pending.
    await ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}
