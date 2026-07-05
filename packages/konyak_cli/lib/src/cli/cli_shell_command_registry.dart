final class CliShellCommandGroup {
  const CliShellCommandGroup({
    required this.name,
    required this.summary,
    required this.commands,
  });

  final String name;
  final String summary;
  final List<CliShellCommandSpec> commands;
}

final class CliShellCommandSpec {
  const CliShellCommandSpec({
    required this.path,
    required this.summary,
    required this.supportsJson,
    required this.compatibilityAliases,
  });

  final List<String> path;
  final String summary;
  final bool supportsJson;
  final List<String> compatibilityAliases;
}

const cliShellCommandGroups = <CliShellCommandGroup>[
  CliShellCommandGroup(
    name: 'bottle',
    summary: 'Manage Konyak bottles.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['bottle', 'list'],
        summary: 'List bottles.',
        supportsJson: true,
        compatibilityAliases: <String>['list-bottles'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'show'],
        summary: 'Show bottle details.',
        supportsJson: true,
        compatibilityAliases: <String>['inspect-bottle'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'create'],
        summary: 'Create a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['create-bottle'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'rename'],
        summary: 'Rename a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['rename-bottle'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'move'],
        summary: 'Move a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['move-bottle'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'delete'],
        summary: 'Delete a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['delete-bottle'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'export'],
        summary: 'Export a bottle archive.',
        supportsJson: true,
        compatibilityAliases: <String>['export-bottle-archive'],
      ),
      CliShellCommandSpec(
        path: <String>['bottle', 'import'],
        summary: 'Import a bottle archive.',
        supportsJson: true,
        compatibilityAliases: <String>['import-bottle-archive'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'program',
    summary: 'Inspect and run Windows programs in bottles.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['program', 'list'],
        summary: 'List programs discovered in a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['list-bottle-programs'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'run'],
        summary: 'Run a Windows program in a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['run-program'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'pin'],
        summary: 'Pin a Windows program.',
        supportsJson: true,
        compatibilityAliases: <String>['pin-program'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'unpin'],
        summary: 'Unpin a Windows program.',
        supportsJson: true,
        compatibilityAliases: <String>['unpin-program'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'rename'],
        summary: 'Rename a pinned Windows program.',
        supportsJson: true,
        compatibilityAliases: <String>['rename-pinned-program'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'settings', 'get'],
        summary: 'Get program settings.',
        supportsJson: true,
        compatibilityAliases: <String>['get-program-settings'],
      ),
      CliShellCommandSpec(
        path: <String>['program', 'settings', 'set'],
        summary: 'Set program settings.',
        supportsJson: true,
        compatibilityAliases: <String>['set-program-settings'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'runtime',
    summary: 'Manage Konyak-owned runtimes.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['runtime', 'list'],
        summary: 'List managed runtimes.',
        supportsJson: true,
        compatibilityAliases: <String>['list-runtimes'],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'validate'],
        summary: 'Validate a managed runtime.',
        supportsJson: true,
        compatibilityAliases: <String>['validate-runtime'],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'install'],
        summary: 'Install a managed runtime.',
        supportsJson: true,
        compatibilityAliases: <String>[
          'install-macos-wine',
          'install-linux-wine',
        ],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'reinstall'],
        summary: 'Reinstall a managed runtime.',
        supportsJson: true,
        compatibilityAliases: <String>[
          'install-macos-wine --reinstall',
          'install-linux-wine --reinstall',
        ],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'update', 'check'],
        summary: 'Check for a runtime update.',
        supportsJson: true,
        compatibilityAliases: <String>['check-runtime-update'],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'update', 'install'],
        summary: 'Install a runtime update.',
        supportsJson: true,
        compatibilityAliases: <String>['install-runtime-update'],
      ),
      CliShellCommandSpec(
        path: <String>['runtime', 'import', 'gptk'],
        summary: 'Import user-provided GPTK or D3DMetal files.',
        supportsJson: true,
        compatibilityAliases: <String>['install-gptk-wine'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'winetricks',
    summary: 'List and run managed Winetricks verbs.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['winetricks', 'list'],
        summary: 'List available Winetricks verbs.',
        supportsJson: true,
        compatibilityAliases: <String>['list-winetricks-verbs'],
      ),
      CliShellCommandSpec(
        path: <String>['winetricks', 'run'],
        summary: 'Run a Winetricks verb in a bottle.',
        supportsJson: true,
        compatibilityAliases: <String>['run-winetricks'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'process',
    summary: 'Inspect and stop Wine processes.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['process', 'list'],
        summary: 'List Wine processes.',
        supportsJson: true,
        compatibilityAliases: <String>['list-wine-processes'],
      ),
      CliShellCommandSpec(
        path: <String>['process', 'kill'],
        summary: 'Terminate one Wine process.',
        supportsJson: true,
        compatibilityAliases: <String>['terminate-wine-process'],
      ),
      CliShellCommandSpec(
        path: <String>['process', 'kill-all'],
        summary: 'Terminate Wine processes.',
        supportsJson: true,
        compatibilityAliases: <String>['terminate-wine-processes'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'update',
    summary: 'Check and install Konyak app updates.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['update', 'check'],
        summary: 'Check for a Konyak app update.',
        supportsJson: true,
        compatibilityAliases: <String>['check-app-update'],
      ),
      CliShellCommandSpec(
        path: <String>['update', 'install'],
        summary: 'Install a Konyak app update.',
        supportsJson: true,
        compatibilityAliases: <String>['install-app-update'],
      ),
    ],
  ),
  CliShellCommandGroup(
    name: 'shell',
    summary: 'Manage user-level shell integration.',
    commands: <CliShellCommandSpec>[
      CliShellCommandSpec(
        path: <String>['shell', 'install'],
        summary: 'Install the user-level shell launcher.',
        supportsJson: true,
        compatibilityAliases: <String>[],
      ),
      CliShellCommandSpec(
        path: <String>['shell', 'uninstall'],
        summary: 'Remove the user-level shell launcher.',
        supportsJson: true,
        compatibilityAliases: <String>[],
      ),
      CliShellCommandSpec(
        path: <String>['shell', 'status'],
        summary: 'Show shell launcher status.',
        supportsJson: true,
        compatibilityAliases: <String>[],
      ),
    ],
  ),
];

const cliShellInternalCompatibilityCommands = <String>[
  'check-macos-setup',
  'get-app-settings',
  'install-linux-file-associations',
  'launch-pinned-program',
  'open-bottle-location',
  'open-program-location',
  'open-url',
  'run-bottle-command',
  'set-app-settings',
  'set-runtime-settings',
  'set-windows-version',
  'suggest-graphics-backend',
];
