import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'external_payload_helpers.dart';
import 'gptk_wine_installation.dart';

const requiredGptkD3DMetalLegacyWindowsFileNames = <String>['atidxx64.dll'];

const requiredGptkD3DMetalCoreWindowsFileNames = <String>[
  'd3d11.dll',
  'd3d12.dll',
  'dxgi.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

const requiredGptkD3DMetalWindowsFileNames = <String>[
  ...requiredGptkD3DMetalLegacyWindowsFileNames,
  ...requiredGptkD3DMetalCoreWindowsFileNames,
];

const requiredGptkD3DMetalLegacyUnixFileNames = <String>['atidxx64.so'];

const requiredGptkD3DMetalCoreUnixFileNames = <String>[
  'd3d11.so',
  'd3d12.so',
  'dxgi.so',
  'nvapi64.so',
  'nvngx.so',
];

const requiredGptkD3DMetalUnixFileNames = <String>[
  ...requiredGptkD3DMetalLegacyUnixFileNames,
  ...requiredGptkD3DMetalCoreUnixFileNames,
];

List<String> requiredGptkD3DMetalWindowsFileNamesForVersion(
  GptkWineImportVersion version,
) {
  return switch (version) {
    GptkWineImportVersion.auto => requiredGptkD3DMetalWindowsFileNames,
    GptkWineImportVersion.gptk3 => requiredGptkD3DMetalWindowsFileNames,
    GptkWineImportVersion.gptk4 => requiredGptkD3DMetalCoreWindowsFileNames,
  };
}

List<String> requiredGptkD3DMetalUnixFileNamesForVersion(
  GptkWineImportVersion version,
) {
  return switch (version) {
    GptkWineImportVersion.auto => requiredGptkD3DMetalUnixFileNames,
    GptkWineImportVersion.gptk3 => requiredGptkD3DMetalUnixFileNames,
    GptkWineImportVersion.gptk4 => requiredGptkD3DMetalCoreUnixFileNames,
  };
}

final class GptkD3DMetalSourceResolution {
  GptkD3DMetalSourceResolution({
    required this.source,
    required Iterable<String> mountRoots,
  }) : mountRoots = List.unmodifiable(mountRoots);

  final GptkD3DMetalSource source;
  final List<String> mountRoots;

  void dispose() {
    for (var index = mountRoots.length - 1; index >= 0; index -= 1) {
      Process.runSync('hdiutil', <String>['detach', mountRoots[index]]);
    }
  }
}

GptkD3DMetalSourceResolution? resolveGptkD3DMetalSourcePath(String sourcePath) {
  final mountRoots = <String>[];
  try {
    final source = resolveGptkD3DMetalSourceKeepingMounts(
      sourcePath,
      mountRoots,
    );
    if (source == null) {
      disposeGptkMountRoots(mountRoots);
      return null;
    }
    return GptkD3DMetalSourceResolution(source: source, mountRoots: mountRoots);
  } on FileSystemException {
    disposeGptkMountRoots(mountRoots);
    rethrow;
  } on ProcessException {
    disposeGptkMountRoots(mountRoots);
    rethrow;
  }
}

GptkD3DMetalSource? resolveGptkD3DMetalSourceKeepingMounts(
  String sourcePath,
  List<String> mountRoots,
) {
  final sourceType = FileSystemEntity.typeSync(sourcePath, followLinks: false);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory) {
    if (baseName(sourcePath).endsWith('.app')) {
      for (final appSourceRoot in gptkD3DMetalAppSourceRoots(sourcePath)) {
        final appSource = resolveGptkD3DMetalSource(appSourceRoot.path);
        if (appSource != null) {
          return appSource;
        }
      }
    }

    final directSource = resolveGptkD3DMetalSource(sourcePath);
    if (directSource != null) {
      return directSource;
    }

    final redist = findDirectoryNamed(
      Directory(sourcePath),
      name: 'redist',
      maxDepth: 3,
    );
    if (redist != null) {
      return resolveGptkD3DMetalSource(redist.path);
    }
    return null;
  }

  if (sourceType == FileSystemEntityType.file && sourcePath.endsWith('.dmg')) {
    final mountRoot = mountGptkDmg(sourcePath);
    if (mountRoot == null) {
      return null;
    }
    mountRoots.add(mountRoot);

    final mountedSource = resolveGptkD3DMetalSourceKeepingMounts(
      mountRoot,
      mountRoots,
    );
    if (mountedSource != null) {
      return mountedSource;
    }

    final nestedDmg = findDmgFile(Directory(mountRoot), maxDepth: 2);
    if (nestedDmg != null) {
      return resolveGptkD3DMetalSourceKeepingMounts(nestedDmg.path, mountRoots);
    }
  }

  return null;
}

List<Directory> gptkD3DMetalAppSourceRoots(String appBundlePath) {
  return <Directory>[
    Directory(joinPath(appBundlePath, const ['Contents', 'Resources', 'wine'])),
    Directory(
      joinPath(appBundlePath, const [
        'Contents',
        'SharedSupport',
        'CrossOver',
        'lib64',
        'apple_gptk',
      ]),
    ),
  ];
}

String? mountGptkDmg(String dmgPath) {
  final mountRoot = Directory.systemTemp.createTempSync('konyak-gptk-mount-');
  final result = Process.runSync('hdiutil', <String>[
    'attach',
    dmgPath,
    '-readonly',
    '-nobrowse',
    '-mountpoint',
    mountRoot.path,
  ]);
  if (result.exitCode != 0) {
    deleteDirectoryIfPresent(mountRoot);
    return null;
  }
  return mountRoot.path;
}

void disposeGptkMountRoots(List<String> mountRoots) {
  for (var index = mountRoots.length - 1; index >= 0; index -= 1) {
    Process.runSync('hdiutil', <String>['detach', mountRoots[index]]);
  }
}

Directory? findDirectoryNamed(
  Directory root, {
  required String name,
  required int maxDepth,
}) {
  if (maxDepth < 0 || !root.existsSync()) {
    return null;
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is Directory && baseName(entry.path) == name) {
      return entry;
    }
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final found = findDirectoryNamed(entry, name: name, maxDepth: maxDepth - 1);
    if (found != null) {
      return found;
    }
  }
  return null;
}

File? findDmgFile(Directory root, {required int maxDepth}) {
  if (maxDepth < 0 || !root.existsSync()) {
    return null;
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is File && entry.path.endsWith('.dmg')) {
      return entry;
    }
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final found = findDmgFile(entry, maxDepth: maxDepth - 1);
    if (found != null) {
      return found;
    }
  }
  return null;
}

Either<String, Unit> validateGptkD3DMetalSource(
  GptkD3DMetalSource source, {
  required GptkWineImportVersion detectedVersion,
}) {
  final frameworkBinary = d3dMetalFrameworkBinary(source.framework.path);
  if (frameworkBinary == null || !File(frameworkBinary).existsSync()) {
    return const Left<String, Unit>(
      'D3DMetal.framework does not contain a D3DMetal binary.',
    );
  }
  if (!looksLikeMachO(File(frameworkBinary))) {
    return const Left<String, Unit>(
      'D3DMetal.framework is not a Mach-O framework binary. Konyak '
      'rejects fixture text files and incomplete GPTK copies.',
    );
  }
  if (!looksLikeMachO(source.dylib)) {
    return const Left<String, Unit>(
      'libd3dshared.dylib is not a Mach-O binary. Konyak rejects fixture '
      'text files and incomplete GPTK copies.',
    );
  }
  if (!looksLikePE(source.d3d12Dll)) {
    return const Left<String, Unit>(
      'd3d12.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  if (!looksLikePE(source.d3d11Dll)) {
    return const Left<String, Unit>(
      'd3d11.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  if (!looksLikePE(source.dxgiDll)) {
    return const Left<String, Unit>(
      'dxgi.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  for (final dllName in requiredGptkD3DMetalWindowsFileNamesForVersion(
    detectedVersion,
  )) {
    final path = gptkD3DMetalWindowsPayloadPath(source.windowsDllRoot, dllName);
    if (path == null) {
      return Left<String, Unit>('GPTK/D3DMetal payload is missing $dllName.');
    }
    if (!looksLikePE(File(path))) {
      return Left<String, Unit>(
        '$dllName is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.',
      );
    }
  }
  for (final libraryName in requiredGptkD3DMetalUnixFileNamesForVersion(
    detectedVersion,
  )) {
    final path = gptkD3DMetalUnixPayloadPath(
      source.unixLibraryRoot,
      libraryName,
    );
    if (path == null) {
      return Left<String, Unit>(
        'GPTK/D3DMetal payload is missing $libraryName.',
      );
    }
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      if (Link(path).targetSync() != '../../external/libd3dshared.dylib') {
        return Left<String, Unit>(
          '$libraryName must be a symlink to '
          '../../external/libd3dshared.dylib.',
        );
      }
    } else if (type == FileSystemEntityType.file) {
      if (!looksLikeMachO(File(path))) {
        return Left<String, Unit>(
          '$libraryName is not a Mach-O binary. Select an official or '
          'compatible Game Porting Toolkit distribution.',
        );
      }
    } else {
      return Left<String, Unit>(
        'GPTK/D3DMetal payload path is unsupported: $libraryName.',
      );
    }
  }
  for (final libraryName in const <String>['d3d11.so', 'd3d12.so', 'dxgi.so']) {
    final path = gptkD3DMetalUnixPayloadPath(
      source.unixLibraryRoot,
      libraryName,
    );
    if (path == null ||
        FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.link ||
        Link(path).targetSync() != '../../external/libd3dshared.dylib') {
      return Left<String, Unit>(
        '$libraryName must be a symlink to '
        '../../external/libd3dshared.dylib.',
      );
    }
  }
  return const Right<String, Unit>(unit);
}

Either<String, GptkWineImportVersion> detectGptkD3DMetalPayloadVersion(
  GptkD3DMetalSource source,
) {
  final frameworkVersion = d3dMetalFrameworkVersion(source.framework.path);
  if (frameworkVersion == null || frameworkVersion.trim().isEmpty) {
    return const Left<String, GptkWineImportVersion>(
      'D3DMetal.framework does not contain GPTK version metadata.',
    );
  }

  final detectedVersion = gptkD3DMetalPayloadVersionFromFrameworkVersion(
    frameworkVersion,
  );
  if (detectedVersion == null) {
    return Left<String, GptkWineImportVersion>(
      'Unsupported GPTK/D3DMetal framework version: $frameworkVersion.',
    );
  }

  return Right<String, GptkWineImportVersion>(detectedVersion);
}

GptkWineImportVersion? gptkD3DMetalPayloadVersionFromFrameworkVersion(
  String frameworkVersion,
) {
  final normalized = frameworkVersion.trim().toLowerCase();
  if (normalized == '3' ||
      normalized.startsWith('3.') ||
      normalized.startsWith('3b')) {
    return GptkWineImportVersion.gptk3;
  }
  if (normalized == '4' ||
      normalized.startsWith('4.') ||
      normalized.startsWith('4b')) {
    return GptkWineImportVersion.gptk4;
  }

  return null;
}

GptkD3DMetalSource? resolveGptkD3DMetalSource(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory &&
      baseName(sourcePath) == 'D3DMetal.framework') {
    return gptkD3DMetalSourceFromExternalRoot(Directory(dirname(sourcePath)));
  }

  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  final directSource = gptkD3DMetalSourceFromExternalRoot(
    Directory(sourcePath),
  );
  if (directSource != null) {
    return directSource;
  }

  final directExternalCandidate = Directory(
    joinPath(sourcePath, const ['external']),
  );
  final directExternalSource = gptkD3DMetalSourceFromExternalRoot(
    directExternalCandidate,
  );
  if (directExternalSource != null) {
    return directExternalSource;
  }

  final candidate = Directory(joinPath(sourcePath, const ['lib', 'external']));
  return gptkD3DMetalSourceFromExternalRoot(candidate);
}

GptkD3DMetalSource? gptkD3DMetalSourceFromExternalRoot(Directory externalRoot) {
  final framework = Directory(
    joinPath(externalRoot.path, const ['D3DMetal.framework']),
  );
  final dylib = File(joinPath(externalRoot.path, const ['libd3dshared.dylib']));
  final libRoot = Directory(dirname(externalRoot.path));
  final payloadRoot = baseName(libRoot.path) == 'lib'
      ? Directory(dirname(libRoot.path))
      : libRoot;
  final windowsDllRoot = Directory(
    joinPath(libRoot.path, const ['wine', 'x86_64-windows']),
  );
  final unixLibraryRoot = Directory(
    joinPath(libRoot.path, const ['wine', 'x86_64-unix']),
  );
  final dllSource = resolveGptkD3DMetalWindowsDlls(windowsDllRoot);
  if (framework.existsSync() &&
      dylib.existsSync() &&
      unixLibraryRoot.existsSync() &&
      dllSource != null) {
    return GptkD3DMetalSource(
      payloadRoot: payloadRoot,
      externalRoot: externalRoot,
      windowsDllRoot: windowsDllRoot,
      unixLibraryRoot: unixLibraryRoot,
      framework: framework,
      dylib: dylib,
      d3d11Dll: dllSource.d3d11Dll,
      d3d12Dll: dllSource.d3d12Dll,
      dxgiDll: dllSource.dxgiDll,
    );
  }

  return null;
}

class GptkD3DMetalWindowsDllSource {
  const GptkD3DMetalWindowsDllSource({
    required this.d3d11Dll,
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final File d3d11Dll;
  final File d3d12Dll;
  final File dxgiDll;
}

GptkD3DMetalWindowsDllSource? resolveGptkD3DMetalWindowsDlls(
  Directory windowsDllRoot,
) {
  final d3d12 = File(joinPath(windowsDllRoot.path, const ['d3d12.dll']));
  final d3d11 = File(joinPath(dirname(d3d12.path), const ['d3d11.dll']));
  final dxgi = File(joinPath(dirname(d3d12.path), const ['dxgi.dll']));
  if (d3d11.existsSync() && d3d12.existsSync() && dxgi.existsSync()) {
    return GptkD3DMetalWindowsDllSource(
      d3d11Dll: d3d11,
      d3d12Dll: d3d12,
      dxgiDll: dxgi,
    );
  }

  return null;
}

String? gptkD3DMetalWindowsPayloadPath(
  Directory windowsDllRoot,
  String destinationName,
) {
  return firstExistingFile(
    windowsDllRoot,
    gptkD3DMetalSourceNames(destinationName),
  );
}

String? gptkD3DMetalUnixPayloadPath(
  Directory unixLibraryRoot,
  String destinationName,
) {
  return firstExistingFileSystemEntity(
    unixLibraryRoot,
    gptkD3DMetalSourceNames(destinationName),
  );
}

List<String> gptkD3DMetalSourceNames(String destinationName) {
  return switch (destinationName) {
    'nvngx.dll' => const <String>['nvngx.dll', 'nvngx-on-metalfx.dll'],
    'nvngx.so' => const <String>['nvngx.so', 'nvngx-on-metalfx.so'],
    _ => <String>[destinationName],
  };
}

String? firstExistingFile(Directory root, Iterable<String> names) {
  for (final name in names) {
    final path = joinPath(root.path, [name]);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String? firstExistingFileSystemEntity(Directory root, Iterable<String> names) {
  for (final name in names) {
    final path = joinPath(root.path, [name]);
    if (FileSystemEntity.typeSync(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return path;
    }
  }
  return null;
}

String? d3dMetalFrameworkBinary(String frameworkPath) {
  for (final relativePath in const <List<String>>[
    <String>['D3DMetal'],
    <String>['Versions', 'A', 'D3DMetal'],
  ]) {
    final path = joinPath(frameworkPath, relativePath);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String? d3dMetalFrameworkVersion(String frameworkPath) {
  final infoPlist = d3dMetalFrameworkInfoPlist(frameworkPath);
  if (infoPlist == null) {
    return null;
  }

  return plistStringValue(infoPlist, 'CFBundleShortVersionString') ??
      plistStringValue(infoPlist, 'CFBundleVersion');
}

File? d3dMetalFrameworkInfoPlist(String frameworkPath) {
  for (final relativePath in const <List<String>>[
    <String>['Resources', 'Info.plist'],
    <String>['Versions', 'A', 'Resources', 'Info.plist'],
  ]) {
    final file = File(joinPath(frameworkPath, relativePath));
    if (file.existsSync()) {
      return file;
    }
  }

  return null;
}

String? plistStringValue(File plist, String key) {
  return plutilRawValue(plist, key) ?? xmlPlistStringValue(plist, key);
}

String? plutilRawValue(File plist, String key) {
  try {
    final result = Process.runSync('plutil', <String>[
      '-extract',
      key,
      'raw',
      '-o',
      '-',
      plist.path,
    ]);
    if (result.exitCode != 0) {
      return null;
    }

    final value = processOutputToString(result.stdout).trim();
    if (value.isEmpty) {
      return null;
    }

    return value;
  } on ProcessException {
    return null;
  }
}

String? xmlPlistStringValue(File plist, String key) {
  try {
    final contents = plist.readAsStringSync();
    final match = RegExp(
      '<key>\\s*${RegExp.escape(key)}\\s*</key>\\s*<string>([^<]+)</string>',
      dotAll: true,
    ).firstMatch(contents);

    return match?.group(1)?.trim();
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

bool looksLikeMachO(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 4) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(4);
      if (header.length < 4) {
        return false;
      }
      final magic =
          header[0] << 24 | header[1] << 16 | header[2] << 8 | header[3];
      return magic == 0xfeedface ||
          magic == 0xcefaedfe ||
          magic == 0xfeedfacf ||
          magic == 0xcffaedfe ||
          magic == 0xcafebabe ||
          magic == 0xbebafeca;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

bool looksLikePE(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 2) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(2);
      return header.length == 2 && header[0] == 0x4d && header[1] == 0x5a;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}
