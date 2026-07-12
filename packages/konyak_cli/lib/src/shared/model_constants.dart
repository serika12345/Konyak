const cliSchemaVersion = 1;
const runtimeStackSchemaVersion = 1;
const konyakAppId = 'konyak';
const konyakAppVersion = String.fromEnvironment(
  'KONYAK_APP_VERSION',
  defaultValue: '1.0.8',
);
const konyakMacosBundleIdentifier = 'app.konyak.Konyak';
const konyakAppVersionUrl =
    'https://api.github.com/repos/serika12345/Konyak/releases/latest';
const runtimeStackManifestFileName = '.konyak-runtime-stack.json';
const linuxWineRuntimeId = 'konyak-linux-wine';
const macosWineRuntimeId = 'konyak-macos-wine';
const macosWineArchiveFileName = 'macos-wine.tar.xz';
const macosWineRuntimeRepository = 'serika12345/konyak-macos-runtime';
const macosWineRuntimeDefaultReleaseTag = 'crossover-26.1.0-konyak.3';
const macosWineRuntimeSourceManifestFileName =
    'konyak-macos-wine-runtime-stack-source.json';
const macosWineRuntimeReleaseUrl =
    'https://api.github.com/repos/$macosWineRuntimeRepository/releases/latest';
const macosWineRuntimeSourceManifestUrl =
    'https://github.com/$macosWineRuntimeRepository/releases/download/'
    '$macosWineRuntimeDefaultReleaseTag/$macosWineRuntimeSourceManifestFileName';
const macosWineVersionUrl = macosWineRuntimeReleaseUrl;
const rosettaRuntimePath = '/Library/Apple/usr/libexec/oah/libRosettaRuntime';
const rosettaInstallCommand = <String>[
  '/usr/sbin/softwareupdate',
  '--install-rosetta',
  '--agree-to-license',
];
