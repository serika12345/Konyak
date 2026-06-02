import 'package:flutter/material.dart';

import '../app_constants.dart';

class KonyakMenuDefinition {
  KonyakMenuDefinition({
    required this.label,
    required List<KonyakMenuItemDefinition> items,
  }) : items = List.unmodifiable(items);

  final String label;
  final List<KonyakMenuItemDefinition> items;
}

class KonyakMenuItemDefinition {
  const KonyakMenuItemDefinition({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class KonyakMenuBar extends StatelessWidget {
  KonyakMenuBar({super.key, required List<KonyakMenuDefinition> menus})
    : menus = List.unmodifiable(menus);

  final List<KonyakMenuDefinition> menus;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Container(
      key: const ValueKey('linux-menu-bar'),
      height: 38,
      decoration: BoxDecoration(
        color: colors.windowBackground,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: MenuBar(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.windowBackground),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        ),
        children: [
          for (final menu in menus)
            SubmenuButton(
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(colors.text),
                minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 10),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -3,
                ),
              ),
              menuChildren: [
                for (final item in menu.items)
                  MenuItemButton(
                    leadingIcon: Icon(item.icon, size: 16),
                    onPressed: item.onPressed,
                    child: Text(item.label),
                  ),
              ],
              child: Text(menu.label),
            ),
        ],
      ),
    );
  }
}
