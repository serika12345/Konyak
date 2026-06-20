//
//  ThumbnailProvider.swift
//  Konyak
//
//  This file is part of Konyak.
//
//  SPDX-License-Identifier: MIT
//

import AppKit
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {
  override func provideThumbnail(
    for request: QLFileThumbnailRequest,
    _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
  ) {
    guard request.fileURL.pathExtension.lowercased() == "exe",
      let image = PortableExecutableIconExtractor.iconImage(from: request.fileURL)
    else {
      handler(nil, nil)
      return
    }

    let canvasSize = thumbnailCanvasSize(from: request.maximumSize)
    let reply = QLThumbnailReply(contextSize: canvasSize) {
      guard let graphicsContext = NSGraphicsContext.current else {
        return false
      }

      graphicsContext.imageInterpolation = .high
      let bounds = CGRect(origin: .zero, size: canvasSize)
      graphicsContext.cgContext.clear(bounds)
      image.draw(
        in: fittedRect(imageSize: image.bestDisplaySize, canvasSize: canvasSize),
        from: CGRect(origin: .zero, size: image.bestDisplaySize),
        operation: .sourceOver,
        fraction: 1
      )
      return true
    }

    handler(reply, nil)
  }
}

private func thumbnailCanvasSize(from maximumSize: CGSize) -> CGSize {
  CGSize(width: max(maximumSize.width, 16), height: max(maximumSize.height, 16))
}

private func fittedRect(imageSize: CGSize, canvasSize: CGSize) -> CGRect {
  guard imageSize.width > 0, imageSize.height > 0 else {
    return CGRect(origin: .zero, size: canvasSize)
  }

  let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
  let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
  return CGRect(
    x: (canvasSize.width - size.width) / 2,
    y: (canvasSize.height - size.height) / 2,
    width: size.width,
    height: size.height
  )
}

private extension NSImage {
  var bestDisplaySize: CGSize {
    if size.width > 0, size.height > 0 {
      return size
    }

    let representation = representations.max {
      ($0.pixelsWide * $0.pixelsHigh) < ($1.pixelsWide * $1.pixelsHigh)
    }
    guard let representation else {
      return CGSize(width: 1, height: 1)
    }

    return CGSize(width: max(representation.pixelsWide, 1), height: max(representation.pixelsHigh, 1))
  }
}
