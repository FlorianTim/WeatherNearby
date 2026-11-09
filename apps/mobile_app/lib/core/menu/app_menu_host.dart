import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_menu.dart';

/// Draws [menus] around [child] and runs the chosen command through
/// [onCommand].
///
/// - [AppMenuStyle.native]: a `PlatformMenuBar`; the keys are registered with
///   the operating system.
/// - [AppMenuStyle.bar]: a Flutter `MenuBar` above [child]. **F10** opens the
///   first menu, as in every desktop application, and the arrow keys then
///   walk it. The items register their own keys.
/// - [AppMenuStyle.none]: no bar; the keys are bound to the focus path of
///   [child] so a hardware keyboard on a tablet still works.
///
/// It brings its own `Overlay`, because `MaterialApp.router` puts its
/// Navigator (and so its Overlay) *below* the `builder` this widget sits in.
class AppMenuHost extends StatefulWidget {
  const AppMenuHost({
    super.key,
    required this.menus,
    required this.onCommand,
    required this.child,
    required this.semanticLabel,
    this.style,
  });

  final List<AppMenuGroup> menus;
  final AppMenuCommandHandler onCommand;
  final Widget child;

  /// Accessible name of the menu bar.
  final String semanticLabel;

  /// Overrides [AppMenuStyle.detect]; tests pin it.
  final AppMenuStyle? style;

  @override
  State<AppMenuHost> createState() => _AppMenuHostState();
}

class _AppMenuHostState extends State<AppMenuHost> {
  final MenuController _first = MenuController();
  late final OverlayEntry _entry = OverlayEntry(builder: _content);

  AppMenuStyle get _style => widget.style ?? AppMenuStyle.detect();

  @override
  void didUpdateWidget(AppMenuHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The overlay entry builds from `widget`, so a new child (every
    // navigation) or new labels need an explicit rebuild.
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  void _run(String id) => widget.onCommand(id);

  Widget _content(BuildContext context) {
    switch (_style) {
      case AppMenuStyle.native:
        return PlatformMenuBar(
          menus: [for (final group in widget.menus) _platformMenu(group)],
          child: widget.child,
        );
      case AppMenuStyle.bar:
        return CallbackShortcuts(
          bindings: {
            ..._keyBindings(),
            const SingleActivator(LogicalKeyboardKey.f10): () {
              if (widget.menus.isNotEmpty) _first.open();
            },
          },
          child: Column(
            children: [
              Semantics(
                container: true,
                label: widget.semanticLabel,
                child: MenuBar(
                  children: [
                    for (var i = 0; i < widget.menus.length; i++)
                      _submenu(widget.menus[i], i == 0 ? _first : null),
                  ],
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        );
      case AppMenuStyle.none:
        return CallbackShortcuts(bindings: _keyBindings(), child: widget.child);
    }
  }

  /// The keys of the enabled entries, bound to the page.
  ///
  /// A Flutter `MenuBar` registers an entry's shortcut only while its menu
  /// is built — that is, open — so a closed bar would ignore its own keys.
  Map<ShortcutActivator, VoidCallback> _keyBindings() => {
    for (final group in widget.menus)
      for (final item in group.items)
        if (item.shortcut != null && item.enabled)
          item.shortcut!: () => _run(item.id),
  };

  PlatformMenu _platformMenu(AppMenuGroup group) {
    final members = <PlatformMenuItem>[];
    var run = <PlatformMenuItem>[];
    for (final item in group.items) {
      if (item.dividerBefore && run.isNotEmpty) {
        members.add(PlatformMenuItemGroup(members: run));
        run = <PlatformMenuItem>[];
      }
      run.add(
        PlatformMenuItem(
          label: item.label,
          shortcut: item.shortcut,
          onSelected: item.enabled ? () => _run(item.id) : null,
        ),
      );
    }
    if (run.isNotEmpty) members.add(PlatformMenuItemGroup(members: run));
    return PlatformMenu(label: group.label, menus: members);
  }

  Widget _submenu(AppMenuGroup group, MenuController? controller) {
    final children = <Widget>[];
    for (final item in group.items) {
      if (item.dividerBefore && children.isNotEmpty) {
        children.add(const Divider(height: 1));
      }
      children.add(
        MenuItemButton(
          shortcut: item.shortcut,
          onPressed: item.enabled ? () => _run(item.id) : null,
          child: Text(item.label),
        ),
      );
    }
    return SubmenuButton(
      controller: controller,
      menuChildren: children,
      child: Text(group.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
