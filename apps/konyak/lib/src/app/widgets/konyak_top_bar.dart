import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import 'konyak_toolbar_action.dart';

class KonyakTopBar extends StatelessWidget {
  const KonyakTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onRefresh,
    required this.onShowProcessManager,
    required this.onShowSettings,
    required this.onCreateBottle,
    required this.onViewLatestLog,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onShowProcessManager;
  final VoidCallback? onShowSettings;
  final VoidCallback? onCreateBottle;
  final VoidCallback? onViewLatestLog;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
          child: Row(
            children: [
              if (onBack != null)
                KonyakToolbarAction(
                  tooltip: localizations.backToBottle,
                  icon: Icons.chevron_left,
                  onPressed: onBack,
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 14),
                ),
              ),
              KonyakToolbarAction(
                tooltip: localizations.createBottleAction,
                icon: Icons.add,
                onPressed: onCreateBottle,
              ),
              KonyakToolbarAction(
                tooltip: localizations.refreshBottles,
                icon: Icons.sync,
                onPressed: onRefresh,
              ),
              KonyakToolbarAction(
                tooltip: localizations.processManager,
                icon: Icons.memory_outlined,
                onPressed: onShowProcessManager,
              ),
              KonyakToolbarAction(
                tooltip: localizations.settings,
                icon: Icons.settings_outlined,
                onPressed: onShowSettings,
              ),
              KonyakToolbarAction(
                tooltip: localizations.viewLatestLog,
                icon: Icons.description_outlined,
                onPressed: onViewLatestLog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
