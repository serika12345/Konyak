part of '../../konyak_cli.dart';

const cliSchemaVersion = 1;
const runtimeStackSchemaVersion = 1;
const konyakAppId = 'konyak';
const konyakAppVersion = '1.0.0';
const konyakMacosBundleIdentifier = 'app.konyak.Konyak';
const konyakAppVersionUrl =
    'https://api.github.com/repos/serika12345/Konyak/releases/latest';
const runtimeStackManifestFileName = '.konyak-runtime-stack.json';
const linuxWineRuntimeId = 'konyak-linux-wine';
const macosWineRuntimeId = 'konyak-macos-wine';
const macosWineArchiveUrl =
    'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz';
const macosWineArchiveFileName = 'macos-wine.tar.xz';
const macosWineVersionUrl =
    'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest';
const winetricksScriptUrl =
    'https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks';
const _rosettaRuntimePath = '/Library/Apple/usr/libexec/oah/libRosettaRuntime';
const _rosettaInstallCommand = <String>[
  '/usr/sbin/softwareupdate',
  '--install-rosetta',
  '--agree-to-license',
];
