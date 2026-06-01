import 'dart:io';

import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';

class PinnedProgramIcon extends StatelessWidget {
  const PinnedProgramIcon({super.key, required this.program});

  final PinnedProgramSummary program;

  @override
  Widget build(BuildContext context) {
    final iconPath = program.iconPath;
    if (iconPath == null || iconPath.trim().isEmpty) {
      return const PinnedProgramFallbackIcon();
    }

    try {
      return Image.memory(
        File(iconPath).readAsBytesSync(),
        key: ValueKey('pinned-program-icon-${program.path}'),
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const PinnedProgramFallbackIcon(),
      );
    } on FileSystemException {
      return const PinnedProgramFallbackIcon();
    }
  }
}

class PinnedProgramFallbackIcon extends StatelessWidget {
  const PinnedProgramFallbackIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return Icon(
      Icons.web_asset_outlined,
      color: colors.pinnedProgramIcon,
      size: 44,
    );
  }
}
