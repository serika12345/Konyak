part of '../../konyak_cli.dart';

const cliSchemaVersion = 1;
const runtimeStackSchemaVersion = 1;
const konyakAppId = 'konyak';
const konyakAppVersion = '1.0.2';
const konyakMacosBundleIdentifier = 'app.konyak.Konyak';
const konyakAppVersionUrl =
    'https://api.github.com/repos/serika12345/Konyak/releases/latest';
const runtimeStackManifestFileName = '.konyak-runtime-stack.json';
const linuxWineRuntimeId = 'konyak-linux-wine';
const macosWineRuntimeId = 'konyak-macos-wine';
const macosWineArchiveFileName = 'macos-wine.tar.xz';
const macosWineRuntimeRepository = 'serika12345/konyak-macos-runtime';
const macosWineRuntimeDefaultReleaseTag = 'crossover-26.1.0-konyak.0';
const macosWineRuntimeSourceManifestFileName =
    'konyak-macos-wine-runtime-stack-source.json';
const macosWineRuntimeReleaseUrl =
    'https://api.github.com/repos/$macosWineRuntimeRepository/releases/latest';
const macosWineRuntimeSourceManifestUrl =
    'https://github.com/$macosWineRuntimeRepository/releases/download/'
    '$macosWineRuntimeDefaultReleaseTag/$macosWineRuntimeSourceManifestFileName';
const macosWineVersionUrl = macosWineRuntimeReleaseUrl;
const _rosettaRuntimePath = '/Library/Apple/usr/libexec/oah/libRosettaRuntime';
const _rosettaInstallCommand = <String>[
  '/usr/sbin/softwareupdate',
  '--install-rosetta',
  '--agree-to-license',
];
