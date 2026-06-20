//
//  PortableExecutableIconExtractor.swift
//  Konyak
//
//  This file is part of Konyak.
//
//  SPDX-License-Identifier: MIT
//

import AppKit

enum PortableExecutableIconExtractor {
  static func iconImage(from url: URL) -> NSImage? {
    guard let data = try? Data(contentsOf: url),
      let image = PortableExecutableImage.parse(data),
      let iconData = peIconData(from: image)
    else {
      return nil
    }

    return NSImage(data: iconData)
  }

  private static func peIconData(from image: PortableExecutableImage) -> Data? {
    let groupResources = PeResourceReader.leaves(in: image, typeId: PeResourceType.rtGroupIcon)
    guard !groupResources.isEmpty else {
      return nil
    }

    var iconResources: [Int: Data] = [:]
    for resource in PeResourceReader.leaves(in: image, typeId: PeResourceType.rtIcon) {
      guard let iconId = resource.ids.first else {
        continue
      }
      iconResources[iconId] = iconResources[iconId] ?? resource.data
    }

    for group in groupResources {
      if let iconData = icoData(fromGroupIconResource: group.data, iconResources: iconResources) {
        return iconData
      }
    }

    return nil
  }

  private static func icoData(
    fromGroupIconResource groupData: Data,
    iconResources: [Int: Data]
  ) -> Data? {
    guard let entries = icoEntries(fromGroupIconResource: groupData, iconResources: iconResources),
      !entries.isEmpty
    else {
      return nil
    }

    return icoData(fromEntries: entries)
  }

  private static func icoEntries(
    fromGroupIconResource groupData: Data,
    iconResources: [Int: Data]
  ) -> [IcoImageEntry]? {
    guard let count = groupData.uint16(at: 4),
      count > 0,
      groupData.count >= 6 + Int(count) * 14
    else {
      return nil
    }

    var entries: [IcoImageEntry] = []
    for index in 0..<Int(count) {
      let offset = 6 + index * 14
      guard let iconId = groupData.uint16(at: offset + 12),
        let iconData = iconResources[Int(iconId)]
      else {
        continue
      }

      entries.append(
        IcoImageEntry(
          width: groupData[offset],
          height: groupData[offset + 1],
          colorCount: groupData[offset + 2],
          planes: groupData.uint16(at: offset + 4) ?? 0,
          bitCount: groupData.uint16(at: offset + 6) ?? 0,
          data: iconData
        )
      )
    }

    return entries
  }

  private static func icoData(fromEntries entries: [IcoImageEntry]) -> Data? {
    var header = Data(repeating: 0, count: 6 + entries.count * 16)
    header.writeUInt16(1, at: 2)
    header.writeUInt16(UInt16(entries.count), at: 4)

    var imageOffset = header.count
    for (index, entry) in entries.enumerated() {
      guard let dataSize = UInt32(exactly: entry.data.count),
        let dataOffset = UInt32(exactly: imageOffset)
      else {
        return nil
      }

      let offset = 6 + index * 16
      header[offset] = entry.width
      header[offset + 1] = entry.height
      header[offset + 2] = entry.colorCount
      header.writeUInt16(entry.planes, at: offset + 4)
      header.writeUInt16(entry.bitCount, at: offset + 6)
      header.writeUInt32(dataSize, at: offset + 8)
      header.writeUInt32(dataOffset, at: offset + 12)
      imageOffset += entry.data.count
    }

    var output = header
    for entry in entries {
      output.append(entry.data)
    }
    return output
  }
}

private enum PeResourceType {
  static let rtIcon = 3
  static let rtGroupIcon = 14
}

private struct IcoImageEntry {
  let width: UInt8
  let height: UInt8
  let colorCount: UInt8
  let planes: UInt16
  let bitCount: UInt16
  let data: Data
}

struct PortableExecutableImage {
  let bytes: Data
  let resourceRva: UInt32?
  let resourceRootOffset: Int?

  private let sections: [PeSection]

  func rawOffset(forRva rva: UInt32) -> Int? {
    let target = UInt64(rva)
    for section in sections {
      let sectionStart = UInt64(section.virtualAddress)
      let sectionSize = UInt64(max(section.virtualSize, section.rawSize))
      guard target >= sectionStart, target < sectionStart + sectionSize else {
        continue
      }

      let rawOffset = UInt64(section.rawOffset) + target - sectionStart
      guard rawOffset <= UInt64(Int.max) else {
        return nil
      }
      return Int(rawOffset)
    }

    return nil
  }

  static func parse(_ bytes: Data) -> PortableExecutableImage? {
    guard let header = PeHeader.parse(bytes),
      let sections = PeSection.parseSections(in: bytes, header: header)
    else {
      return nil
    }

    let imageWithoutResourceRoot = PortableExecutableImage(
      bytes: bytes,
      resourceRva: header.resourceRva,
      resourceRootOffset: nil,
      sections: sections
    )

    return PortableExecutableImage(
      bytes: bytes,
      resourceRva: header.resourceRva,
      resourceRootOffset: header.resourceRva.flatMap {
        imageWithoutResourceRoot.rawOffset(forRva: $0)
      },
      sections: sections
    )
  }
}

private struct PeHeader {
  let peHeaderOffset: Int
  let sectionCount: UInt16
  let optionalHeaderOffset: Int
  let optionalHeaderSize: UInt16
  let resourceRva: UInt32?

  static func parse(_ bytes: Data) -> PeHeader? {
    guard bytes.count >= 0x40,
      bytes[0] == 0x4d,
      bytes[1] == 0x5a,
      let peOffset = bytes.uint32(at: 0x3c),
      let peHeaderOffset = Int(exactly: peOffset),
      hasPeSignature(in: bytes, at: peHeaderOffset),
      let sectionCount = bytes.uint16(at: peHeaderOffset + 6),
      let optionalHeaderSize = bytes.uint16(at: peHeaderOffset + 20),
      optionalHeaderSize >= 2
    else {
      return nil
    }

    let optionalHeaderOffset = peHeaderOffset + 24
    guard let dataDirectoryOffset = dataDirectoryOffset(in: bytes, at: optionalHeaderOffset) else {
      return nil
    }

    return PeHeader(
      peHeaderOffset: peHeaderOffset,
      sectionCount: sectionCount,
      optionalHeaderOffset: optionalHeaderOffset,
      optionalHeaderSize: optionalHeaderSize,
      resourceRva: bytes.uint32(at: dataDirectoryOffset + 8 * 2)
    )
  }

  private static func hasPeSignature(in bytes: Data, at offset: Int) -> Bool {
    offset + 24 <= bytes.count
      && bytes[offset] == 0x50
      && bytes[offset + 1] == 0x45
      && bytes[offset + 2] == 0
      && bytes[offset + 3] == 0
  }

  private static func dataDirectoryOffset(in bytes: Data, at optionalHeaderOffset: Int) -> Int? {
    switch bytes.uint16(at: optionalHeaderOffset) {
    case 0x010b:
      return optionalHeaderOffset + 96
    case 0x020b:
      return optionalHeaderOffset + 112
    default:
      return nil
    }
  }
}

private struct PeSection {
  let virtualSize: UInt32
  let virtualAddress: UInt32
  let rawSize: UInt32
  let rawOffset: UInt32

  static func parseSections(in bytes: Data, header: PeHeader) -> [PeSection]? {
    let sectionHeaderOffset = header.optionalHeaderOffset + Int(header.optionalHeaderSize)
    var sections: [PeSection] = []

    for index in 0..<Int(header.sectionCount) {
      let offset = sectionHeaderOffset + index * 40
      guard offset + 40 <= bytes.count,
        let virtualSize = bytes.uint32(at: offset + 8),
        let virtualAddress = bytes.uint32(at: offset + 12),
        let rawSize = bytes.uint32(at: offset + 16),
        let rawOffset = bytes.uint32(at: offset + 20)
      else {
        return nil
      }

      sections.append(
        PeSection(
          virtualSize: virtualSize,
          virtualAddress: virtualAddress,
          rawSize: rawSize,
          rawOffset: rawOffset
        )
      )
    }

    return sections
  }
}
