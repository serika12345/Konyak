import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../widgets/icon_file_image.dart';

class PinnedProgramIcon extends StatelessWidget {
  const PinnedProgramIcon({super.key, required this.program});

  final PinnedProgramSummary program;

  @override
  Widget build(BuildContext context) {
    return IconFileImage(
      key: ValueKey('pinned-program-icon-${program.path}'),
      path: program.iconPath,
      width: 44,
      height: 44,
      fallback: const PinnedProgramFallbackIcon(),
    );
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
