import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../widgets/konyak_menu_bar.dart';
import 'home_contracts.dart';

class KonyakHomeMenuBar extends StatelessWidget {
  const KonyakHomeMenuBar({
    super.key,
    required this.showAboutAction,
    required this.showSettingsAction,
    required this.checkKonyakUpdatesAction,
    required this.importBottleArchiveAction,
    required this.reinstallRuntimeAction,
  });

  final KonyakHomeActionAvailability showAboutAction;
  final KonyakHomeActionAvailability showSettingsAction;
  final KonyakHomeActionAvailability checkKonyakUpdatesAction;
  final KonyakHomeActionAvailability importBottleArchiveAction;
  final KonyakHomeActionAvailability reinstallRuntimeAction;

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
              onPressed: homeActionCallback(showAboutAction),
            ),
            KonyakMenuItemDefinition(
              label: localizations.settingsEllipsisMenu,
              icon: Icons.settings_outlined,
              onPressed: homeActionCallback(showSettingsAction),
            ),
            KonyakMenuItemDefinition(
              label: localizations.checkForUpdatesMenuItem,
              icon: Icons.system_update_alt,
              onPressed: homeActionCallback(checkKonyakUpdatesAction),
            ),
            KonyakMenuItemDefinition(
              label: localizations.reinstallLinuxRuntime,
              icon: Icons.restart_alt,
              onPressed: homeActionCallback(reinstallRuntimeAction),
            ),
          ],
        ),
        KonyakMenuDefinition(
          label: localizations.file,
          items: [
            KonyakMenuItemDefinition(
              label: localizations.importBottle,
              icon: Icons.file_upload_outlined,
              onPressed: homeActionCallback(importBottleArchiveAction),
            ),
          ],
        ),
      ],
    );
  }
}
