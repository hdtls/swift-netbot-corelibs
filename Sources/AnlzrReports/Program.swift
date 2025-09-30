//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import NIOConcurrencyHelpers

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
public struct Program: Hashable, Codable, Sendable {

  /// Indicates the name of the program.
  /// This is dependent on the current localization of the referenced program, and is suitable for presentation to the user.
  public var localizedName: String = "Unknown"

  /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
  public var bundleURL: URL?

  /// Indicates the URL to the application's executable.
  public var executableURL: URL?

  /// Indicates the icon TIFF representation data of the application.
  public var iconTIFFRepresentation: Data?

  public init(
    localizedName: String = "Unknown",
    bundleURL: URL? = nil,
    executableURL: URL? = nil,
    iconTIFFRepresentation: Data? = nil
  ) {
    self.localizedName = localizedName
    self.bundleURL = bundleURL
    self.executableURL = executableURL
    self.iconTIFFRepresentation = iconTIFFRepresentation
  }
}

@available(SwiftStdlib 5.3, *)
extension Program: Identifiable {
  public var id: String { persistentModelID }

  public var persistentModelID: String { localizedName }
}

#if swift(>=6.3) || canImport(Darwin)
  @available(SwiftStdlib 5.9, *)
  extension Program {

    public typealias PersistentModel = V1._Program

    public init(persistentModel: PersistentModel) {
      localizedName = persistentModel.localizedName
      bundleURL = persistentModel.bundleURL
      executableURL = persistentModel.executableURL
      iconTIFFRepresentation = persistentModel.iconTIFFRepresentation
    }
  }
#endif
