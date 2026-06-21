import 'package:flutter/material.dart';

final class BottleToolAction {
  const BottleToolAction._({required this.kind, required this.id});

  const BottleToolAction.command(String id)
    : this._(kind: BottleToolActionKind.command, id: id);

  const BottleToolAction.location(String id)
    : this._(kind: BottleToolActionKind.location, id: id);

  final BottleToolActionKind kind;
  final String id;
}

enum BottleToolActionKind { command, location }

class BottleToolsDialog extends StatelessWidget {
  const BottleToolsDialog({super.key, required this.bottleName});

  final String bottleName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tools for $bottleName'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in _bottleToolItems)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
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
    label: 'Open Wine Configuration',
    icon: Icons.tune,
    action: BottleToolAction.command('winecfg'),
  ),
  _BottleToolItem(
    label: 'Registry Editor',
    icon: Icons.edit_note,
    action: BottleToolAction.command('regedit'),
  ),
  _BottleToolItem(
    label: 'Control Panel',
    icon: Icons.settings_applications,
    action: BottleToolAction.command('control'),
  ),
  _BottleToolItem(
    label: 'Uninstall Programs',
    icon: Icons.delete_outline,
    action: BottleToolAction.command('uninstaller'),
  ),
  _BottleToolItem(
    label: 'Task Manager',
    icon: Icons.monitor_heart_outlined,
    action: BottleToolAction.command('taskmgr'),
  ),
  _BottleToolItem(
    label: 'Command Prompt',
    icon: Icons.terminal,
    action: BottleToolAction.command('cmd'),
  ),
  _BottleToolItem(
    label: 'File Explorer',
    icon: Icons.folder_open,
    action: BottleToolAction.command('explorer'),
  ),
  _BottleToolItem(
    label: 'DirectX Diagnostic Report',
    icon: Icons.memory,
    action: BottleToolAction.command('dxdiag'),
  ),
  _BottleToolItem(
    label: 'Windows Version',
    icon: Icons.info_outline,
    action: BottleToolAction.command('winver'),
  ),
  _BottleToolItem(
    label: 'Terminal',
    icon: Icons.terminal,
    action: BottleToolAction.command('terminal'),
  ),
  _BottleToolItem(
    label: 'Open C: Drive',
    icon: Icons.drive_folder_upload,
    action: BottleToolAction.location('c-drive'),
  ),
  _BottleToolItem(
    label: 'Open Bottle Folder',
    icon: Icons.folder,
    action: BottleToolAction.location('root'),
  ),
];

final class _BottleToolItem {
  const _BottleToolItem({
    required this.label,
    required this.icon,
    required this.action,
  });

  final String label;
  final IconData icon;
  final BottleToolAction action;
}
