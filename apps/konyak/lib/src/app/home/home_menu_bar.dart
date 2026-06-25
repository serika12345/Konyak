import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../widgets/konyak_menu_bar.dart';

class KonyakHomeMenuBar extends StatelessWidget {
  const KonyakHomeMenuBar({
    super.key,
    required this.onShowAbout,
    required this.onShowSettings,
    required this.onCheckKonyakUpdates,
    required this.onImportBottleArchive,
    required this.onReinstallRuntime,
  });

  final VoidCallback? onShowAbout;
  final VoidCallback? onShowSettings;
  final VoidCallback? onCheckKonyakUpdates;
  final VoidCallback? onImportBottleArchive;
  final VoidCallback? onReinstallRuntime;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return KonyakMenuBar(
      menus: [
        KonyakMenuDefinition(
          label: 'Konyak',
          items: [
            KonyakMenuItemDefinition(
              label: localizations.aboutKonyak,
              icon: Icons.info_outline,
              onPressed: onShowAbout,
            ),
            KonyakMenuItemDefinition(
              label: localizations.settingsEllipsisMenu,
              icon: Icons.settings_outlined,
              onPressed: onShowSettings,
            ),
            KonyakMenuItemDefinition(
              label: localizations.checkForUpdatesMenuItem,
              icon: Icons.system_update_alt,
              onPressed: onCheckKonyakUpdates,
            ),
            KonyakMenuItemDefinition(
              label: localizations.reinstallLinuxRuntime,
              icon: Icons.restart_alt,
              onPressed: onReinstallRuntime,
            ),
          ],
        ),
        KonyakMenuDefinition(
          label: localizations.file,
          items: [
            KonyakMenuItemDefinition(
              label: localizations.importBottle,
              icon: Icons.file_upload_outlined,
              onPressed: onImportBottleArchive,
            ),
          ],
        ),
      ],
    );
  }
}
