part of '../../../konyak_cli.dart';

final class _PortableExecutableImage {
  const _PortableExecutableImage({
    required this.bytes,
    required this.machine,
    required this.sections,
    required this.importRva,
    required this.importRootOffset,
    required this.resourceRva,
    required this.resourceRootOffset,
  });

  final Uint8List bytes;
  final int machine;
  final List<_PeSection> sections;
  final int? importRva;
  final int? importRootOffset;
  final int? resourceRva;
  final int? resourceRootOffset;

  String? get architecture {
    return switch (machine) {
      0x014c => 'x86',
      0x8664 => 'x86_64',
      0xaa64 => 'arm64',
      0x01c4 => 'arm',
      _ => null,
    };
  }

  int? rawOffsetForRva(int rva) {
    for (final section in sections) {
      final sectionSize = max(section.virtualSize, section.rawSize);
      if (rva >= section.virtualAddress &&
          rva < section.virtualAddress + sectionSize) {
        return section.rawOffset + (rva - section.virtualAddress);
      }
    }

    return null;
  }

  List<String> get importDllNames {
    final rootOffset = importRootOffset;
    if (rootOffset == null) {
      return const <String>[];
    }

    final names = <String>[];
    for (var offset = rootOffset; offset + 20 <= bytes.length; offset += 20) {
      final originalFirstThunk = _readUint32(bytes, offset) ?? 0;
      final timeDateStamp = _readUint32(bytes, offset + 4) ?? 0;
      final forwarderChain = _readUint32(bytes, offset + 8) ?? 0;
      final nameRva = _readUint32(bytes, offset + 12) ?? 0;
      final firstThunk = _readUint32(bytes, offset + 16) ?? 0;
      if (originalFirstThunk == 0 &&
          timeDateStamp == 0 &&
          forwarderChain == 0 &&
          nameRva == 0 &&
          firstThunk == 0) {
        break;
      }

      final nameOffset = rawOffsetForRva(nameRva);
      if (nameOffset == null) {
        continue;
      }

      final name = _nullTerminatedAsciiString(bytes, nameOffset, bytes.length);
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }

    return List.unmodifiable(names);
  }

  static _PortableExecutableImage? parse(Uint8List bytes) {
    if (bytes.length < 0x40 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
      return null;
    }

    final peOffset = _readUint32(bytes, 0x3c);
    if (peOffset == null ||
        peOffset + 24 > bytes.length ||
        bytes[peOffset] != 0x50 ||
        bytes[peOffset + 1] != 0x45 ||
        bytes[peOffset + 2] != 0x00 ||
        bytes[peOffset + 3] != 0x00) {
      return null;
    }

    final machine = _readUint16(bytes, peOffset + 4);
    final sectionCount = _readUint16(bytes, peOffset + 6);
    final optionalHeaderSize = _readUint16(bytes, peOffset + 20);
    if (machine == null ||
        sectionCount == null ||
        optionalHeaderSize == null ||
        optionalHeaderSize < 2) {
      return null;
    }

    final optionalHeaderOffset = peOffset + 24;
    final magic = _readUint16(bytes, optionalHeaderOffset);
    final dataDirectoryOffset = switch (magic) {
      0x010b => optionalHeaderOffset + 96,
      0x020b => optionalHeaderOffset + 112,
      _ => null,
    };
    if (dataDirectoryOffset == null) {
      return null;
    }

    final importDirectoryOffset = dataDirectoryOffset + 8;
    final importRva = _readUint32(bytes, importDirectoryOffset);
    final resourceDirectoryOffset = dataDirectoryOffset + 8 * 2;
    final resourceRva = _readUint32(bytes, resourceDirectoryOffset);
    final sectionHeaderOffset = optionalHeaderOffset + optionalHeaderSize;
    final sections = <_PeSection>[];
    for (var index = 0; index < sectionCount; index += 1) {
      final offset = sectionHeaderOffset + index * 40;
      if (offset + 40 > bytes.length) {
        return null;
      }

      final virtualSize = _readUint32(bytes, offset + 8);
      final virtualAddress = _readUint32(bytes, offset + 12);
      final rawSize = _readUint32(bytes, offset + 16);
      final rawOffset = _readUint32(bytes, offset + 20);
      if (virtualSize == null ||
          virtualAddress == null ||
          rawSize == null ||
          rawOffset == null) {
        return null;
      }
      sections.add(
        _PeSection(
          virtualSize: virtualSize,
          virtualAddress: virtualAddress,
          rawSize: rawSize,
          rawOffset: rawOffset,
        ),
      );
    }

    final image = _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      importRva: importRva,
      importRootOffset: null,
      resourceRva: resourceRva,
      resourceRootOffset: null,
    );

    return _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      importRva: importRva,
      importRootOffset: importRva == null || importRva == 0
          ? null
          : image.rawOffsetForRva(importRva),
      resourceRva: resourceRva,
      resourceRootOffset: resourceRva == null
          ? null
          : image.rawOffsetForRva(resourceRva),
    );
  }
}

final class _PeSection {
  const _PeSection({
    required this.virtualSize,
    required this.virtualAddress,
    required this.rawSize,
    required this.rawOffset,
  });

  final int virtualSize;
  final int virtualAddress;
  final int rawSize;
  final int rawOffset;
}
