import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../bottles/bottle_tool_action.dart';

class BottleToolsDialog extends StatelessWidget {
  const BottleToolsDialog({
    super.key,
    required this.bottleName,
    this.availableKinds = BottleToolActionKind.values,
  });

  final String bottleName;
  final Iterable<BottleToolActionKind> availableKinds;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.toolsForBottle(bottleName)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in _bottleToolItems)
                if (availableKinds.contains(item.action.kind))
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(
                      _localizedBottleToolLabel(item.label, localizations),
                    ),
                    dense: true,
                    onTap: () => Navigator.of(context).pop(item.action),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

const _bottleToolItems = <_BottleToolItem>[
  _BottleToolItem(
    label: _BottleToolLabel.openWineConfiguration,
    icon: Icons.tune,
    action: BottleToolAction.command('winecfg'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.registryEditor,
    icon: Icons.edit_note,
    action: BottleToolAction.command('regedit'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.controlPanel,
    icon: Icons.settings_applications,
    action: BottleToolAction.command('control'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.uninstallPrograms,
    icon: Icons.delete_outline,
    action: BottleToolAction.command('uninstaller'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.simulateReboot,
    icon: Icons.restart_alt,
    action: BottleToolAction.command('simulate-reboot'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.taskManager,
    icon: Icons.monitor_heart_outlined,
    action: BottleToolAction.command('taskmgr'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.commandPrompt,
    icon: Icons.terminal,
    action: BottleToolAction.command('cmd'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.fileExplorer,
    icon: Icons.folder_open,
    action: BottleToolAction.command('explorer'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.directxDiagnosticReport,
    icon: Icons.memory,
    action: BottleToolAction.command('dxdiag'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.windowsVersion,
    icon: Icons.info_outline,
    action: BottleToolAction.command('winver'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.terminal,
    icon: Icons.terminal,
    action: BottleToolAction.command('terminal'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.openCDrive,
    icon: Icons.drive_folder_upload,
    action: BottleToolAction.location('c-drive'),
  ),
  _BottleToolItem(
    label: _BottleToolLabel.openBottleFolder,
    icon: Icons.folder,
    action: BottleToolAction.location('root'),
  ),
];

enum _BottleToolLabel {
  openWineConfiguration,
  registryEditor,
  controlPanel,
  uninstallPrograms,
  simulateReboot,
  taskManager,
  commandPrompt,
  fileExplorer,
  directxDiagnosticReport,
  windowsVersion,
  terminal,
  openCDrive,
  openBottleFolder,
}

String _localizedBottleToolLabel(
  _BottleToolLabel label,
  KonyakLocalizations localizations,
) {
  return switch (label) {
    _BottleToolLabel.openWineConfiguration =>
      localizations.openWineConfiguration,
    _BottleToolLabel.registryEditor => localizations.registryEditor,
    _BottleToolLabel.controlPanel => localizations.controlPanel,
    _BottleToolLabel.uninstallPrograms => localizations.uninstallPrograms,
    _BottleToolLabel.simulateReboot => localizations.simulateReboot,
    _BottleToolLabel.taskManager => localizations.taskManager,
    _BottleToolLabel.commandPrompt => localizations.commandPrompt,
    _BottleToolLabel.fileExplorer => localizations.fileExplorer,
    _BottleToolLabel.directxDiagnosticReport =>
      localizations.directxDiagnosticReport,
    _BottleToolLabel.windowsVersion => localizations.windowsVersion,
    _BottleToolLabel.terminal => localizations.terminal,
    _BottleToolLabel.openCDrive => localizations.openCDrive,
    _BottleToolLabel.openBottleFolder => localizations.openBottleFolder,
  };
}

final class _BottleToolItem {
  const _BottleToolItem({
    required this.label,
    required this.icon,
    required this.action,
  });

  final _BottleToolLabel label;
  final IconData icon;
  final BottleToolAction action;
}
