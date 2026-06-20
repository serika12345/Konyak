//
//  PeResourceReader.swift
//  Konyak
//
//  This file is part of Konyak.
//
//  SPDX-License-Identifier: MIT
//

import Foundation

enum PeResourceReader {
  static func leaves(in image: PortableExecutableImage, typeId: Int) -> [PeResourceLeaf] {
    guard let resourceRootOffset = image.resourceRootOffset else {
      return []
    }

    for entry in directoryEntries(in: image.bytes, directoryOffset: resourceRootOffset) {
      guard entry.id == typeId, entry.isDirectory else {
        continue
      }

      return leavesFromDirectory(
        in: image,
        directoryOffset: resourceRootOffset + entry.targetOffset,
        ids: []
      )
    }

    return []
  }

  private static func leavesFromDirectory(
    in image: PortableExecutableImage,
    directoryOffset: Int,
    ids: [Int]
  ) -> [PeResourceLeaf] {
    guard let resourceRootOffset = image.resourceRootOffset else {
      return []
    }

    var leaves: [PeResourceLeaf] = []
    for entry in directoryEntries(in: image.bytes, directoryOffset: directoryOffset) {
      let nextIds = entry.id.map { ids + [$0] } ?? ids
      if entry.isDirectory {
        leaves.append(
          contentsOf: leavesFromDirectory(
            in: image,
            directoryOffset: resourceRootOffset + entry.targetOffset,
            ids: nextIds
          )
        )
        continue
      }

      if let leaf = resourceLeaf(in: image, rootOffset: resourceRootOffset, entry: entry, ids: nextIds) {
        leaves.append(leaf)
      }
    }

    return leaves
  }

  private static func resourceLeaf(
    in image: PortableExecutableImage,
    rootOffset: Int,
    entry: PeResourceDirectoryEntry,
    ids: [Int]
  ) -> PeResourceLeaf? {
    let dataEntryOffset = rootOffset + entry.targetOffset
    guard let dataRva = image.bytes.uint32(at: dataEntryOffset),
      let size = image.bytes.uint32(at: dataEntryOffset + 4),
      let sizeInt = Int(exactly: size),
      let dataOffset = image.rawOffset(forRva: dataRva),
      dataOffset >= 0,
      dataOffset + sizeInt <= image.bytes.count
    else {
      return nil
    }

    return PeResourceLeaf(
      ids: ids,
      data: image.bytes.subdata(in: dataOffset..<dataOffset + sizeInt)
    )
  }

  private static func directoryEntries(in bytes: Data, directoryOffset: Int) -> [PeResourceDirectoryEntry] {
    guard let namedEntryCount = bytes.uint16(at: directoryOffset + 12),
      let idEntryCount = bytes.uint16(at: directoryOffset + 14)
    else {
      return []
    }

    let entryCount = Int(namedEntryCount) + Int(idEntryCount)
    let maximumEntryCount = (bytes.count - (directoryOffset + 16)) / 8
    guard entryCount >= 0, entryCount <= maximumEntryCount else {
      return []
    }

    var entries: [PeResourceDirectoryEntry] = []
    for index in 0..<entryCount {
      let offset = directoryOffset + 16 + index * 8
      guard let nameOrId = bytes.uint32(at: offset),
        let offsetToData = bytes.uint32(at: offset + 4)
      else {
        continue
      }

      entries.append(
        PeResourceDirectoryEntry(
          id: nameOrId & 0x80000000 == 0 ? Int(nameOrId & 0xffff) : nil,
          isDirectory: offsetToData & 0x80000000 != 0,
          targetOffset: Int(offsetToData & 0x7fffffff)
        )
      )
    }

    return entries
  }
}

struct PeResourceLeaf {
  let ids: [Int]
  let data: Data
}

private struct PeResourceDirectoryEntry {
  let id: Int?
  let isDirectory: Bool
  let targetOffset: Int
}

extension Data {
  func uint16(at offset: Int) -> UInt16? {
    guard offset >= 0, offset + 2 <= count else {
      return nil
    }

    return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
  }

  func uint32(at offset: Int) -> UInt32? {
    guard offset >= 0, offset + 4 <= count else {
      return nil
    }

    return UInt32(self[offset])
      | (UInt32(self[offset + 1]) << 8)
      | (UInt32(self[offset + 2]) << 16)
      | (UInt32(self[offset + 3]) << 24)
  }

  mutating func writeUInt16(_ value: UInt16, at offset: Int) {
    self[offset] = UInt8(value & 0xff)
    self[offset + 1] = UInt8((value >> 8) & 0xff)
  }

  mutating func writeUInt32(_ value: UInt32, at offset: Int) {
    self[offset] = UInt8(value & 0xff)
    self[offset + 1] = UInt8((value >> 8) & 0xff)
    self[offset + 2] = UInt8((value >> 16) & 0xff)
    self[offset + 3] = UInt8((value >> 24) & 0xff)
  }
}
