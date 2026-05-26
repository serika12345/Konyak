import 'package:flutter/material.dart';

import '../app_constants.dart';

class KonyakToolbarAction extends StatelessWidget {
  const KonyakToolbarAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: colors.toolbarIcon,
      disabledColor: colors.toolbarDisabledIcon,
      iconSize: 20,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
    );
  }
}
