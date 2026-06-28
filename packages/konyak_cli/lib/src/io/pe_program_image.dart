part of '../../konyak_cli.dart';

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
  final Option<int> importRva;
  final Option<int> importRootOffset;
  final Option<int> resourceRva;
  final Option<int> resourceRootOffset;

  Option<String> get architecture {
    return switch (machine) {
      0x014c => Option.of('x86'),
      0x8664 => Option.of('x86_64'),
      0xaa64 => Option.of('arm64'),
      0x01c4 => Option.of('arm'),
      _ => const Option.none(),
    };
  }

  Option<int> rawOffsetForRva(int rva) {
    for (final section in sections) {
      final sectionSize = max(section.virtualSize, section.rawSize);
      if (rva >= section.virtualAddress &&
          rva < section.virtualAddress + sectionSize) {
        return Option.of(section.rawOffset + (rva - section.virtualAddress));
      }
    }

    return const Option.none();
  }

  List<String> get importDllNames {
    return importRootOffset.match(
      () => const <String>[],
      (rootOffset) =>
          _peImportDllNamesFromOffset(image: this, offset: rootOffset),
    );
  }

  static Option<_PortableExecutableImage> parse(Uint8List bytes) {
    if (bytes.length < 0x40 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
      return const Option.none();
    }

    return _readUint32Option(bytes, 0x3c).flatMap(
      (peOffset) =>
          _parsePortableExecutableAtOffset(bytes: bytes, peOffset: peOffset),
    );
  }
}

Option<_PortableExecutableImage> _parsePortableExecutableAtOffset({
  required Uint8List bytes,
  required int peOffset,
}) {
  if (peOffset + 24 > bytes.length ||
      bytes[peOffset] != 0x50 ||
      bytes[peOffset + 1] != 0x45 ||
      bytes[peOffset + 2] != 0x00 ||
      bytes[peOffset + 3] != 0x00) {
    return const Option.none();
  }

  return _readUint16Option(bytes, peOffset + 4).flatMap(
    (machine) => _readUint16Option(bytes, peOffset + 6).flatMap(
      (sectionCount) => _readUint16Option(bytes, peOffset + 20).flatMap(
        (optionalHeaderSize) => _parsePortableExecutableWithHeader(
          bytes: bytes,
          peOffset: peOffset,
          machine: machine,
          sectionCount: sectionCount,
          optionalHeaderSize: optionalHeaderSize,
        ),
      ),
    ),
  );
}

Option<_PortableExecutableImage> _parsePortableExecutableWithHeader({
  required Uint8List bytes,
  required int peOffset,
  required int machine,
  required int sectionCount,
  required int optionalHeaderSize,
}) {
  if (optionalHeaderSize < 2) {
    return const Option.none();
  }

  final optionalHeaderOffset = peOffset + 24;
  return _readUint16Option(bytes, optionalHeaderOffset).flatMap(
    (magic) =>
        _peDataDirectoryOffset(
          magic: magic,
          optionalHeaderOffset: optionalHeaderOffset,
        ).flatMap((dataDirectoryOffset) {
          final importDirectoryOffset = dataDirectoryOffset + 8;
          final importRva = _readUint32Option(bytes, importDirectoryOffset);
          final resourceDirectoryOffset = dataDirectoryOffset + 8 * 2;
          final resourceRva = _readUint32Option(bytes, resourceDirectoryOffset);
          final sectionHeaderOffset = optionalHeaderOffset + optionalHeaderSize;
          return _peSections(
            bytes: bytes,
            sectionHeaderOffset: sectionHeaderOffset,
            sectionCount: sectionCount,
            index: 0,
          ).map(
            (sections) => _portableExecutableImageWithResourceOffsets(
              bytes: bytes,
              machine: machine,
              sections: sections,
              importRva: importRva,
              resourceRva: resourceRva,
            ),
          );
        }),
  );
}

_PortableExecutableImage _portableExecutableImageWithResourceOffsets({
  required Uint8List bytes,
  required int machine,
  required List<_PeSection> sections,
  required Option<int> importRva,
  required Option<int> resourceRva,
}) {
  final image = _PortableExecutableImage(
    bytes: bytes,
    machine: machine,
    sections: List.unmodifiable(sections),
    importRva: importRva,
    importRootOffset: const Option.none(),
    resourceRva: resourceRva,
    resourceRootOffset: const Option.none(),
  );

  return _PortableExecutableImage(
    bytes: bytes,
    machine: machine,
    sections: List.unmodifiable(sections),
    importRva: importRva,
    importRootOffset: _peOptionalRvaRawOffset(image: image, rva: importRva),
    resourceRva: resourceRva,
    resourceRootOffset: _peOptionalRvaRawOffset(image: image, rva: resourceRva),
  );
}

Option<int> _peOptionalRvaRawOffset({
  required _PortableExecutableImage image,
  required Option<int> rva,
}) {
  return rva.flatMap(
    (value) => value == 0 ? const Option.none() : image.rawOffsetForRva(value),
  );
}

List<String> _peImportDllNamesFromOffset({
  required _PortableExecutableImage image,
  required int offset,
}) {
  if (offset + 20 > image.bytes.length) {
    return const <String>[];
  }

  return _peImportDescriptorAt(image: image, offset: offset).match(
    () => const <String>[],
    (descriptor) {
      if (descriptor.originalFirstThunk == 0 &&
          descriptor.timeDateStamp == 0 &&
          descriptor.forwarderChain == 0 &&
          descriptor.nameRva == 0 &&
          descriptor.firstThunk == 0) {
        return const <String>[];
      }

      return <String>[
        ..._peImportDllNameAtDescriptorOffset(
          image: image,
          nameRva: descriptor.nameRva,
        ).match(
          () => const <String>[],
          (name) => name.isEmpty ? const <String>[] : <String>[name],
        ),
        ..._peImportDllNamesFromOffset(image: image, offset: offset + 20),
      ];
    },
  );
}

Option<
  ({
    int firstThunk,
    int forwarderChain,
    int nameRva,
    int originalFirstThunk,
    int timeDateStamp,
  })
>
_peImportDescriptorAt({
  required _PortableExecutableImage image,
  required int offset,
}) {
  return _readUint32Option(image.bytes, offset).flatMap((originalFirstThunk) {
    return _readUint32Option(image.bytes, offset + 4).flatMap((timeDateStamp) {
      return _readUint32Option(image.bytes, offset + 8).flatMap((
        forwarderChain,
      ) {
        return _readUint32Option(image.bytes, offset + 12).flatMap((nameRva) {
          return _readUint32Option(image.bytes, offset + 16).map((firstThunk) {
            return (
              firstThunk: firstThunk,
              forwarderChain: forwarderChain,
              nameRva: nameRva,
              originalFirstThunk: originalFirstThunk,
              timeDateStamp: timeDateStamp,
            );
          });
        });
      });
    });
  });
}

Option<String> _peImportDllNameAtDescriptorOffset({
  required _PortableExecutableImage image,
  required int nameRva,
}) {
  return image
      .rawOffsetForRva(nameRva)
      .flatMap(
        (nameOffset) => _nullTerminatedAsciiStringOption(
          image.bytes,
          nameOffset,
          image.bytes.length,
        ),
      );
}

Option<int> _peDataDirectoryOffset({
  required int magic,
  required int optionalHeaderOffset,
}) {
  return switch (magic) {
    0x010b => Option.of(optionalHeaderOffset + 96),
    0x020b => Option.of(optionalHeaderOffset + 112),
    _ => const Option.none(),
  };
}

Option<List<_PeSection>> _peSections({
  required Uint8List bytes,
  required int sectionHeaderOffset,
  required int sectionCount,
  required int index,
}) {
  if (index >= sectionCount) {
    return Option.of(const <_PeSection>[]);
  }

  final section = _peSectionAtIndex(
    bytes: bytes,
    sectionHeaderOffset: sectionHeaderOffset,
    index: index,
  );
  final remaining = _peSections(
    bytes: bytes,
    sectionHeaderOffset: sectionHeaderOffset,
    sectionCount: sectionCount,
    index: index + 1,
  );
  return section.flatMap(
    (value) => remaining.map(
      (remainingSections) => <_PeSection>[value, ...remainingSections],
    ),
  );
}

Option<_PeSection> _peSectionAtIndex({
  required Uint8List bytes,
  required int sectionHeaderOffset,
  required int index,
}) {
  final offset = sectionHeaderOffset + index * 40;
  if (offset + 40 > bytes.length) {
    return const Option.none();
  }

  return _readUint32Option(bytes, offset + 8).flatMap(
    (virtualSize) => _readUint32Option(bytes, offset + 12).flatMap(
      (virtualAddress) => _readUint32Option(bytes, offset + 16).flatMap(
        (rawSize) => _readUint32Option(bytes, offset + 20).map(
          (rawOffset) => _PeSection(
            virtualSize: virtualSize,
            virtualAddress: virtualAddress,
            rawSize: rawSize,
            rawOffset: rawOffset,
          ),
        ),
      ),
    ),
  );
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
