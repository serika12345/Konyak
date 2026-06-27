part of '../../../konyak_cli.dart';

String _macosPinnedProgramInfoPlist({
  required _PinnedProgramLauncherManifest manifest,
  required String displayName,
  required String? iconFileName,
}) {
  final bundleIdentifier =
      '$konyakMacosBundleIdentifier.pinned.${manifest.launcherId}';
  final iconPlistEntry = iconFileName == null
      ? ''
      : '''
  <key>CFBundleIconFile</key>
  <string>${_xmlEscape(iconFileName)}</string>
''';

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${_xmlEscape(displayName)}</string>
  <key>CFBundleExecutable</key>
  <string>$_macosPinnedLauncherExecutableName</string>
$iconPlistEntry
  <key>CFBundleIdentifier</key>
  <string>${_xmlEscape(bundleIdentifier)}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${_xmlEscape(displayName)}</string>
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

String _macosLauncherDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String _uniqueMacosLauncherDisplayName(
  String name, {
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final baseName = _macosLauncherDisplayName(name);
  return _uniqueMacosLauncherDisplayNameAtIndex(
    baseName,
    index: 1,
    usedDisplayNames: usedDisplayNames,
    usedBundleNames: usedBundleNames,
  );
}

String _uniqueMacosLauncherDisplayNameAtIndex(
  String baseName, {
  required int index,
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final displayName = index == 1 ? baseName : '$baseName ($index)';
  final displayKey = displayName.toLowerCase();
  final bundleName = _macosLauncherBundleName(displayName);
  final bundleKey = bundleName.toLowerCase();
  if (!usedDisplayNames.contains(displayKey) &&
      !usedBundleNames.contains(bundleKey)) {
    usedDisplayNames.add(displayKey);
    usedBundleNames.add(bundleKey);
    return displayName;
  }

  return _uniqueMacosLauncherDisplayNameAtIndex(
    baseName,
    index: index + 1,
    usedDisplayNames: usedDisplayNames,
    usedBundleNames: usedBundleNames,
  );
}

String _macosLauncherBundleName(String displayName) {
  return '${_macosLauncherBundleBaseName(displayName)}.app';
}

String _macosLauncherBundleBaseName(String displayName) {
  final safeName = displayName
      .replaceAll(RegExp(r'[/\\:]'), '-')
      .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
      .trim();
  return safeName.isEmpty ? 'Konyak Program' : safeName;
}

String _macosPinnedProgramLauncherScript(
  _MacosPinnedProgramLauncherCommand command,
) {
  final changeDirectory = command.workingDirectory.match(
    () => '',
    (workingDirectory) => 'cd ${_posixShellSingleQuote(workingDirectory)}\n',
  );
  final launcherCommand = <String>[
    _posixShellSingleQuote(command.executable),
    ...command.arguments.map(_posixShellSingleQuote),
    'launch-pinned-program',
    '--manifest',
    r'"$manifest"',
    '--json',
  ].join(' ');

  return '''
#!/bin/sh
set -eu
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")/../Resources" && pwd -P)
manifest="\$manifest_dir/$_macosPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _posixShellSingleQuote(String value) {
  return "'${value.replaceAll("'", "'\\''")}'";
}
