import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/menu/app_menus.dart';
import 'package:mobile_app/app/router/routes.dart';
import 'package:mobile_app/core/l10n/generated/app_localizations_en.dart';
import 'package:mobile_app/core/menu/app_menu.dart';

List<AppMenuGroup> _menus({
  String location = AppRoutes.todos,
  bool desktop = true,
  bool mac = false,
}) => buildAppMenus(
  AppLocalizationsEn(),
  location: location,
  desktop: desktop,
  mac: mac,
);

List<AppMenuItem> _items(List<AppMenuGroup> menus) => [
  for (final group in menus) ...group.items,
];

void main() {
  group('the app menu', () {
    test('has Quit only on a desktop', () {
      expect(_items(_menus()).map((i) => i.id), contains(quitMenuId));
      expect(
        _items(_menus(desktop: false)).map((i) => i.id),
        isNot(contains(quitMenuId)),
      );
    });

    test('gives every entry an id of its own', () {
      final ids = _items(_menus()).map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('jumps with Alt+1…4, with Control+Option on a Mac', () {
      final goto = _menus().firstWhere((g) => g.id == 'goto').items;
      expect(goto, hasLength(4));
      expect(goto.first.shortcut?.trigger, LogicalKeyboardKey.digit1);
      expect(goto.first.shortcut?.alt, isTrue);
      expect(goto.first.shortcut?.control, isFalse);

      final mac = _menus(mac: true).firstWhere((g) => g.id == 'goto').items;
      expect(mac.first.shortcut?.control, isTrue);
      expect(mac.first.shortcut?.alt, isTrue);
    });

    test('quits with Ctrl+Q, with Command+Q on a Mac', () {
      final quit = _items(_menus()).firstWhere((i) => i.id == quitMenuId);
      expect(quit.shortcut?.control, isTrue);
      expect(quit.shortcut?.meta, isFalse);

      final mac = _items(
        _menus(mac: true),
      ).firstWhere((i) => i.id == quitMenuId);
      expect(mac.shortcut?.meta, isTrue);
      expect(mac.shortcut?.control, isFalse);
    });

    test('opens the manual with F1', () {
      final manual = _items(_menus()).firstWhere((i) => i.id == 'help:manual');
      expect(manual.shortcut?.trigger, LogicalKeyboardKey.f1);
    });

    test('names every goto entry after a route', () {
      for (final item in _menus().firstWhere((g) => g.id == 'goto').items) {
        expect(gotoRouteOf(item.id), isNotNull, reason: item.id);
      }
      expect(gotoRouteOf('goto:nowhere'), isNull);
      expect(gotoRouteOf('help:manual'), isNull);
    });

    test('maps the help entries to routes', () {
      expect(helpRouteOf('help:manual'), AppRoutes.manual);
      expect(helpRouteOf('help:faq'), AppRoutes.faq);
      expect(helpRouteOf('goto:settings'), isNull);
    });
  });

  group('leaving a screen through the menu', () {
    test('is refused on the splash, the error page and the intro', () {
      for (final route in [
        AppRoutes.splash,
        AppRoutes.startupError,
        AppRoutes.intro,
      ]) {
        expect(menuNavigationAllowed(route), isFalse, reason: route);
      }
      expect(menuNavigationAllowed(AppRoutes.todos), isTrue);
      expect(menuNavigationAllowed('${AppRoutes.settings}?x=1'), isTrue);
    });

    test('disables the navigating entries there, keeps Quit', () {
      final items = _items(_menus(location: AppRoutes.splash));
      expect(
        items.where((i) => i.id != quitMenuId).every((i) => !i.enabled),
        isTrue,
      );
      expect(items.firstWhere((i) => i.id == quitMenuId).enabled, isTrue);
    });
  });
}
