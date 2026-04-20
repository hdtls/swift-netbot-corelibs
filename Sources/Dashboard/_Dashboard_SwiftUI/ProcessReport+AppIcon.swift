// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

#if os(macOS)
  import AppKit
  import SwiftUI
  import UniformTypeIdentifiers

  @available(SwiftStdlib 5.9, *)
  @_spi(SwiftUI) extension V1._ProcessReport {

    nonisolated(unsafe) private static let cache = NSCache<NSString, NSImage>()

    @MainActor public var processImage: NSImage {
      guard let localizedName = program?.localizedName else {
        return NSImage()
      }

      let cacheKey = localizedName as NSString

      if let image = Self.cache.object(forKey: cacheKey) {
        return image
      }

      if let data = program?.iconTIFFRepresentation, let image = NSImage(data: data) {
        Self.cache.setObject(image, forKey: cacheKey)
        return image
      }

      if let processIdentifier,
        let app = NSRunningApplication(processIdentifier: processIdentifier),
        let image = app.icon
      {
        Self.cache.setObject(image, forKey: cacheKey)
        return image
      }

      if let url = program?.bundleURL {
        let image: NSImage
        if #available(macOS 13.0, *) {
          image = NSWorkspace.shared.icon(forFile: url.path())
        } else {
          // Fallback on earlier versions
          image = NSWorkspace.shared.icon(forFile: url.path)
        }
        Self.cache.setObject(image, forKey: cacheKey)
        return image
      }

      if program?.executableURL != nil {
        let image: NSImage
        if #available(macOS 11.0, *) {
          image = NSWorkspace.shared.icon(for: .unixExecutable)
        } else {
          image = NSWorkspace.shared.icon(forFileType: "public.unix-executable")
        }
        Self.cache.setObject(image, forKey: cacheKey)
        return image
      }

      return NSImage()
    }

    @MainActor public var processIcon: EquatableView<ProcessImage> {
      ProcessImage(data: self).equatable()
    }
  }

  @available(SwiftStdlib 5.9, *)
  @_spi(SwiftUI) public struct ProcessImage: View, @MainActor Equatable {
    public static func == (lhs: ProcessImage, rhs: ProcessImage) -> Bool {
      lhs.data.program?.localizedName == rhs.data.program?.localizedName
    }

    private let data: V1._ProcessReport

    public init(data: V1._ProcessReport) {
      self.data = data
    }

    public var body: some View {
      Image(nsImage: data.processImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
#endif
