import 'dart:math';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'external_payload_helpers.dart';

final class PortableExecutableImage {
  const PortableExecutableImage({
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
  final List<PeSection> sections;
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
          peImportDllNamesFromOffset(image: this, offset: rootOffset),
    );
  }

  static Option<PortableExecutableImage> parse(Uint8List bytes) {
    if (bytes.length < 0x40 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
      return const Option.none();
    }

    return readUint32Option(bytes, 0x3c).flatMap(
      (peOffset) =>
          parsePortableExecutableAtOffset(bytes: bytes, peOffset: peOffset),
    );
  }
}

Option<PortableExecutableImage> parsePortableExecutableAtOffset({
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

  return readUint16Option(bytes, peOffset + 4).flatMap(
    (machine) => readUint16Option(bytes, peOffset + 6).flatMap(
      (sectionCount) => readUint16Option(bytes, peOffset + 20).flatMap(
        (optionalHeaderSize) => parsePortableExecutableWithHeader(
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

Option<PortableExecutableImage> parsePortableExecutableWithHeader({
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
  return readUint16Option(bytes, optionalHeaderOffset).flatMap(
    (magic) =>
        peDataDirectoryOffset(
          magic: magic,
          optionalHeaderOffset: optionalHeaderOffset,
        ).flatMap((dataDirectoryOffset) {
          final importDirectoryOffset = dataDirectoryOffset + 8;
          final importRva = readUint32Option(bytes, importDirectoryOffset);
          final resourceDirectoryOffset = dataDirectoryOffset + 8 * 2;
          final resourceRva = readUint32Option(bytes, resourceDirectoryOffset);
          final sectionHeaderOffset = optionalHeaderOffset + optionalHeaderSize;
          return peSections(
            bytes: bytes,
            sectionHeaderOffset: sectionHeaderOffset,
            sectionCount: sectionCount,
            index: 0,
          ).map(
            (sections) => portableExecutableImageWithResourceOffsets(
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

PortableExecutableImage portableExecutableImageWithResourceOffsets({
  required Uint8List bytes,
  required int machine,
  required List<PeSection> sections,
  required Option<int> importRva,
  required Option<int> resourceRva,
}) {
  final image = PortableExecutableImage(
    bytes: bytes,
    machine: machine,
    sections: List.unmodifiable(sections),
    importRva: importRva,
    importRootOffset: const Option.none(),
    resourceRva: resourceRva,
    resourceRootOffset: const Option.none(),
  );

  return PortableExecutableImage(
    bytes: bytes,
    machine: machine,
    sections: List.unmodifiable(sections),
    importRva: importRva,
    importRootOffset: peOptionalRvaRawOffset(image: image, rva: importRva),
    resourceRva: resourceRva,
    resourceRootOffset: peOptionalRvaRawOffset(image: image, rva: resourceRva),
  );
}

Option<int> peOptionalRvaRawOffset({
  required PortableExecutableImage image,
  required Option<int> rva,
}) {
  return rva.flatMap(
    (value) => value == 0 ? const Option.none() : image.rawOffsetForRva(value),
  );
}

List<String> peImportDllNamesFromOffset({
  required PortableExecutableImage image,
  required int offset,
}) {
  if (offset + 20 > image.bytes.length) {
    return const <String>[];
  }

  return peImportDescriptorAt(image: image, offset: offset).match(
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
        ...peImportDllNameAtDescriptorOffset(
          image: image,
          nameRva: descriptor.nameRva,
        ).match(
          () => const <String>[],
          (name) => name.isEmpty ? const <String>[] : <String>[name],
        ),
        ...peImportDllNamesFromOffset(image: image, offset: offset + 20),
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
peImportDescriptorAt({
  required PortableExecutableImage image,
  required int offset,
}) {
  return readUint32Option(image.bytes, offset).flatMap((originalFirstThunk) {
    return readUint32Option(image.bytes, offset + 4).flatMap((timeDateStamp) {
      return readUint32Option(image.bytes, offset + 8).flatMap((
        forwarderChain,
      ) {
        return readUint32Option(image.bytes, offset + 12).flatMap((nameRva) {
          return readUint32Option(image.bytes, offset + 16).map((firstThunk) {
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

Option<String> peImportDllNameAtDescriptorOffset({
  required PortableExecutableImage image,
  required int nameRva,
}) {
  return image
      .rawOffsetForRva(nameRva)
      .flatMap(
        (nameOffset) => nullTerminatedAsciiStringOption(
          image.bytes,
          nameOffset,
          image.bytes.length,
        ),
      );
}

Option<int> peDataDirectoryOffset({
  required int magic,
  required int optionalHeaderOffset,
}) {
  return switch (magic) {
    0x010b => Option.of(optionalHeaderOffset + 96),
    0x020b => Option.of(optionalHeaderOffset + 112),
    _ => const Option.none(),
  };
}

Option<List<PeSection>> peSections({
  required Uint8List bytes,
  required int sectionHeaderOffset,
  required int sectionCount,
  required int index,
}) {
  if (index >= sectionCount) {
    return Option.of(const <PeSection>[]);
  }

  final section = peSectionAtIndex(
    bytes: bytes,
    sectionHeaderOffset: sectionHeaderOffset,
    index: index,
  );
  final remaining = peSections(
    bytes: bytes,
    sectionHeaderOffset: sectionHeaderOffset,
    sectionCount: sectionCount,
    index: index + 1,
  );
  return section.flatMap(
    (value) => remaining.map(
      (remainingSections) => <PeSection>[value, ...remainingSections],
    ),
  );
}

Option<PeSection> peSectionAtIndex({
  required Uint8List bytes,
  required int sectionHeaderOffset,
  required int index,
}) {
  final offset = sectionHeaderOffset + index * 40;
  if (offset + 40 > bytes.length) {
    return const Option.none();
  }

  return readUint32Option(bytes, offset + 8).flatMap(
    (virtualSize) => readUint32Option(bytes, offset + 12).flatMap(
      (virtualAddress) => readUint32Option(bytes, offset + 16).flatMap(
        (rawSize) => readUint32Option(bytes, offset + 20).map(
          (rawOffset) => PeSection(
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

final class PeSection {
  const PeSection({
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
