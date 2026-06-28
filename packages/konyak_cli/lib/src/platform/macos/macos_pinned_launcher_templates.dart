import '../../domain/program/program_mutation_models.dart';
import '../../io/macos_pinned_launchers.dart';
import '../../shared/model_constants.dart';

String macosPinnedProgramInfoPlist({
  required PinnedProgramLauncherManifest manifest,
  required String displayName,
  required String? iconFileName,
}) {
  final bundleIdentifier =
      '$konyakMacosBundleIdentifier.pinned.${manifest.launcherId}';
  final iconPlistEntry = iconFileName == null
      ? ''
      : '''
  <key>CFBundleIconFile</key>
  <string>${xmlEscape(iconFileName)}</string>
''';

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${xmlEscape(displayName)}</string>
  <key>CFBundleExecutable</key>
  <string>$macosPinnedLauncherExecutableName</string>
$iconPlistEntry
  <key>CFBundleIdentifier</key>
  <string>${xmlEscape(bundleIdentifier)}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${xmlEscape(displayName)}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$konyakAppVersion</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
''';
}

String macosLauncherDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String uniqueMacosLauncherDisplayName(
  String name, {
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final baseName = macosLauncherDisplayName(name);
  return uniqueMacosLauncherDisplayNameAtIndex(
    baseName,
    index: 1,
    usedDisplayNames: usedDisplayNames,
    usedBundleNames: usedBundleNames,
  );
}

String uniqueMacosLauncherDisplayNameAtIndex(
  String baseName, {
  required int index,
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final displayName = index == 1 ? baseName : '$baseName ($index)';
  final displayKey = displayName.toLowerCase();
  final bundleName = macosLauncherBundleName(displayName);
  final bundleKey = bundleName.toLowerCase();
  if (!usedDisplayNames.contains(displayKey) &&
      !usedBundleNames.contains(bundleKey)) {
    usedDisplayNames.add(displayKey);
    usedBundleNames.add(bundleKey);
    return displayName;
  }

  return uniqueMacosLauncherDisplayNameAtIndex(
    baseName,
    index: index + 1,
    usedDisplayNames: usedDisplayNames,
    usedBundleNames: usedBundleNames,
  );
}

String macosLauncherBundleName(String displayName) {
  return '${macosLauncherBundleBaseName(displayName)}.app';
}

String macosLauncherBundleBaseName(String displayName) {
  final safeName = displayName
      .replaceAll(RegExp(r'[/\\:]'), '-')
      .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
      .trim();
  return safeName.isEmpty ? 'Konyak Program' : safeName;
}

String macosPinnedProgramLauncherScript(
  MacosPinnedProgramLauncherCommand command,
) {
  final changeDirectory = command.workingDirectory.match(
    () => '',
    (workingDirectory) => 'cd ${posixShellSingleQuote(workingDirectory)}\n',
  );
  final launcherCommand = <String>[
    posixShellSingleQuote(command.executable),
    ...command.arguments.map(posixShellSingleQuote),
    'launch-pinned-program',
    '--manifest',
    r'"$manifest"',
    '--json',
  ].join(' ');

  return '''
#!/bin/sh
set -eu
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")/../Resources" && pwd -P)
manifest="\$manifest_dir/$macosPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

String xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String posixShellSingleQuote(String value) {
  return "'${value.replaceAll("'", "'\\''")}'";
}
