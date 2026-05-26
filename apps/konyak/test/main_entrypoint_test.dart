import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main.dart remains a thin application entrypoint', () {
    final mainFile = _existingFile([
      'lib/main.dart',
      'apps/konyak/lib/main.dart',
    ]);
    final mainSource = mainFile.readAsStringSync();

    expect(
      RegExp(r'^class\s+', multiLine: true).allMatches(mainSource),
      isEmpty,
    );
    expect(mainSource.split('\n'), hasLength(lessThanOrEqualTo(24)));
  });

  test('app code is split into independent feature libraries', () {
    final appDirectory = _existingDirectory([
      'lib/src/app',
      'apps/konyak/lib/src/app',
    ]);
    final appFiles = appDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList(growable: false);

    expect(appFiles, isNotEmpty);
    for (final file in appFiles) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r'^\s*part( of)?\s', multiLine: true).hasMatch(source),
        isFalse,
        reason: '${file.path} must be an independent Dart library',
      );
    }

    expect(
      _relativePaths(appDirectory, appFiles),
      containsAll(<String>[
        'home/home_screen.dart',
        'home/sidebar.dart',
        'bottles/bottle_detail.dart',
        'bottles/bottle_overview.dart',
        'bottles/bottle_configuration_view.dart',
        'bottles/bottle_actions.dart',
        'programs/pinned_programs_section.dart',
        'programs/program_configuration_view.dart',
        'dialogs/app_settings_dialog.dart',
        'dialogs/bottle_management_dialogs.dart',
        'dialogs/bottle_programs_dialog.dart',
        'dialogs/create_bottle_dialog.dart',
        'dialogs/pin_program_dialog.dart',
        'dialogs/run_program_dialog.dart',
        'dialogs/winetricks_dialog.dart',
      ]),
    );
  });

  test('reusable widgets are defined in dedicated widget files', () {
    final appDirectory = _existingDirectory([
      'lib/src/app',
      'apps/konyak/lib/src/app',
    ]);

    final widgetFiles = <String, String>{
      'widgets/blocking_progress_overlay.dart': 'BlockingProgressOverlay',
      'widgets/configuration_controls.dart': 'ConfigurationDropdown',
      'widgets/konyak_bottom_button.dart': 'KonyakBottomButton',
      'widgets/konyak_menu_bar.dart': 'KonyakMenuBar',
      'widgets/konyak_toolbar_action.dart': 'KonyakToolbarAction',
      'widgets/konyak_toggle.dart': 'KonyakToggle',
    };

    for (final entry in widgetFiles.entries) {
      final file = File('${appDirectory.path}/${entry.key}');
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      expect(file.readAsStringSync(), contains('class ${entry.value}'));
    }
  });
}

File _existingFile(List<String> paths) {
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) {
      return file;
    }
  }

  fail('Could not find any of: ${paths.join(', ')}');
}

Directory _existingDirectory(List<String> paths) {
  for (final path in paths) {
    final directory = Directory(path);
    if (directory.existsSync()) {
      return directory;
    }
  }

  fail('Could not find any of: ${paths.join(', ')}');
}

Set<String> _relativePaths(Directory baseDirectory, List<File> files) {
  final basePath = '${baseDirectory.absolute.path}/';

  return files
      .map((file) => file.absolute.path.replaceFirst(basePath, ''))
      .toSet();
}
