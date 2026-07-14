import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_profile_install_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/shared/domain_value_objects.dart';
import 'file_digest_io.dart';

typedef NativeDllAtomicReplace = void Function(String source, String target);

final class DartIoNativeDllInstaller implements NativeDllInstaller {
  DartIoNativeDllInstaller({NativeDllAtomicReplace? atomicReplace})
    : _atomicReplace = atomicReplace ?? _rename;

  final NativeDllAtomicReplace _atomicReplace;

  @override
  NativeDllInstallResult install({
    required BottleRecord bottle,
    required NativeDllPreInstallAction action,
    required ProgramPath resourcePath,
  }) {
    try {
      final source = File(resourcePath.value);
      if (!source.existsSync() ||
          FileSystemEntity.isLinkSync(source.path) ||
          source.statSync().type != FileSystemEntityType.file) {
        return const NativeDllInstallFailed(
          code: 'nativeDllResourceInvalid',
          message: 'Native DLL resource is not a regular file.',
        );
      }
      final machine = _peMachine(source);
      if (machine == null || machine != action.machine.peCoffMachine) {
        return const NativeDllInstallFailed(
          code: 'nativeDllMachineMismatch',
          message: 'Native DLL PE machine does not match the profile action.',
        );
      }

      final bottleRoot = Directory(bottle.path.value);
      final driveC = Directory(_join(bottleRoot.path, 'drive_c'));
      final windows = Directory(_join(driveC.path, 'windows'));
      final destination = Directory(
        _join(windows.path, switch (action.destination) {
          NativeDllDestination.windowsSysWow64 => 'syswow64',
          NativeDllDestination.windowsSystem32 => 'system32',
        }),
      );
      final directories = [bottleRoot, driveC, windows, destination];
      if (directories.any(
        (directory) =>
            !directory.existsSync() ||
            FileSystemEntity.isLinkSync(directory.path) ||
            directory.statSync().type != FileSystemEntityType.directory,
      )) {
        return const NativeDllInstallFailed(
          code: 'nativeDllDestinationInvalid',
          message: 'Native DLL destination is not a safe directory.',
        );
      }
      final rootReal = bottleRoot.resolveSymbolicLinksSync();
      final driveReal = driveC.resolveSymbolicLinksSync();
      final windowsReal = windows.resolveSymbolicLinksSync();
      final destinationReal = destination.resolveSymbolicLinksSync();
      if (!_contains(rootReal, driveReal) ||
          !_contains(driveReal, windowsReal) ||
          !_contains(windowsReal, destinationReal)) {
        return const NativeDllInstallFailed(
          code: 'nativeDllDestinationEscapesBottle',
          message: 'Native DLL destination escapes the bottle.',
        );
      }

      final target = File(_join(destinationReal, action.targetFileName.value));
      if (FileSystemEntity.isLinkSync(target.path)) {
        return const NativeDllInstallFailed(
          code: 'nativeDllTargetSymlink',
          message: 'Native DLL target must not be a symbolic link.',
        );
      }
      if (target.existsSync()) {
        if (target.statSync().type != FileSystemEntityType.file) {
          return const NativeDllInstallFailed(
            code: 'nativeDllTargetInvalid',
            message: 'Native DLL target is not a regular file.',
          );
        }
        final targetDigest = sha256HexDigest(target);
        if (targetDigest.toLowerCase() ==
            action.resource.sha256.value.toLowerCase()) {
          return const NativeDllInstalled(changed: false);
        }
      }

      final temporary = File(
        _join(
          destinationReal,
          '.${action.targetFileName.value}.konyak-${_nonce()}.tmp',
        ),
      );
      try {
        temporary.createSync(exclusive: true);
        final copiedDigest = _copyWithSha256(source, temporary);
        if (copiedDigest.toLowerCase() !=
            action.resource.sha256.value.toLowerCase()) {
          return const NativeDllInstallFailed(
            code: 'nativeDllDigestMismatch',
            message: 'Native DLL resource digest changed after fetch.',
          );
        }
        final copiedMachine = _peMachine(temporary);
        if (copiedMachine == null ||
            copiedMachine != action.machine.peCoffMachine) {
          return const NativeDllInstallFailed(
            code: 'nativeDllMachineMismatch',
            message: 'Native DLL PE machine does not match the profile action.',
          );
        }
        _atomicReplace(temporary.path, target.path);
      } finally {
        if (temporary.existsSync() ||
            FileSystemEntity.isLinkSync(temporary.path)) {
          temporary.deleteSync();
        }
      }
      return const NativeDllInstalled(changed: true);
    } on FileSystemException catch (error) {
      return NativeDllInstallFailed(
        code: 'nativeDllInstallFailed',
        message: error.message,
      );
    } on ArgumentError catch (error) {
      return NativeDllInstallFailed(
        code: 'nativeDllInstallFailed',
        message: error.message.toString(),
      );
    }
  }
}

int? _peMachine(File file) {
  final input = file.openSync();
  try {
    final length = input.lengthSync();
    if (length < 0x40) {
      return null;
    }
    final dosHeader = _readExactAt(input, position: 0, length: 0x40);
    if (dosHeader == null || dosHeader[0] != 0x4d || dosHeader[1] != 0x5a) {
      return null;
    }
    final peOffset = ByteData.sublistView(
      dosHeader,
    ).getUint32(0x3c, Endian.little);
    if (peOffset > length - 6) {
      return null;
    }
    final peHeader = _readExactAt(input, position: peOffset, length: 6);
    if (peHeader == null ||
        peHeader[0] != 0x50 ||
        peHeader[1] != 0x45 ||
        peHeader[2] != 0 ||
        peHeader[3] != 0) {
      return null;
    }
    return ByteData.sublistView(peHeader).getUint16(4, Endian.little);
  } finally {
    input.closeSync();
  }
}

Uint8List? _readExactAt(
  RandomAccessFile file, {
  required int position,
  required int length,
}) {
  file.setPositionSync(position);
  final buffer = Uint8List(length);
  var offset = 0;
  while (offset < length) {
    final count = file.readIntoSync(buffer, offset, length);
    if (count == 0) {
      return null;
    }
    offset += count;
  }
  return buffer;
}

String _copyWithSha256(File source, File destination) {
  final digestSink = _DigestSink();
  final hashInput = sha256.startChunkedConversion(digestSink);
  final output = destination.openSync(mode: FileMode.writeOnlyAppend);
  try {
    final input = source.openSync();
    try {
      final buffer = Uint8List(64 * 1024);
      while (true) {
        final length = input.readIntoSync(buffer);
        if (length == 0) {
          break;
        }
        final chunk = Uint8List.sublistView(buffer, 0, length);
        hashInput.add(chunk);
        output.writeFromSync(chunk);
      }
      output.flushSync();
      hashInput.close();
    } finally {
      input.closeSync();
    }
  } finally {
    output.closeSync();
  }
  return switch (digestSink.value) {
    final Digest digest => digest.toString(),
    _ => throw const FormatException('SHA-256 digest was not produced.'),
  };
}

final class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

bool _contains(String parent, String child) {
  final prefix = parent.endsWith(Platform.pathSeparator)
      ? parent
      : '$parent${Platform.pathSeparator}';
  return child == parent || child.startsWith(prefix);
}

String _join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';

String _nonce() => List<int>.generate(
  16,
  (_) => Random.secure().nextInt(256),
).map((value) => value.toRadixString(16).padLeft(2, '0')).join();

void _rename(String source, String target) {
  File(source).renameSync(target);
}
