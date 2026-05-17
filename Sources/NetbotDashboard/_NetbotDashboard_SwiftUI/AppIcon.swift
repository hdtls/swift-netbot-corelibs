// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if os(macOS)
  import AppKit
  import NetbotLiteData
  import SwiftUI
  import UniformTypeIdentifiers

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @_spi(SwiftUI) extension V1._ProcessReport {

    @MainActor private static let cache = NSCache<NSString, NSImage>()

    @MainActor public var applicationIconImage: NSImage? {
      guard let localizedName = program?.localizedName else {
        return nil
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

      return nil
    }

    @MainActor public var applicationIcon: EquatableView<ApplicationIcon> {
      ApplicationIcon(data: self).equatable()
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @_spi(SwiftUI) extension V1._Program {

    @MainActor public var applicationIconImage: NSImage? {
      processReports.first(where: { $0.applicationIconImage != nil })?.applicationIconImage
    }

    @MainActor public var applicationIcon: EquatableView<ApplicationIcon> {
      ApplicationIcon(data: self).equatable()
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @_spi(SwiftUI) public struct ApplicationIcon: View, @MainActor Equatable {
    public static func == (lhs: ApplicationIcon, rhs: ApplicationIcon) -> Bool {
      lhs.localizedName == rhs.localizedName
    }

    private let localizedName: String?
    private let nsImage: NSImage

    public init(data: V1._ProcessReport) {
      self.localizedName = data.program?.localizedName
      self.nsImage = data.applicationIconImage ?? .init()
    }

    public init(data: V1._Program) {
      self.localizedName = data.localizedName
      self.nsImage = data.applicationIconImage ?? .init()
    }

    public var body: some View {
      Image(nsImage: nsImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
#endif
