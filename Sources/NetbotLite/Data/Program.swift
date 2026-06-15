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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
public struct Program: Hashable, Codable, Sendable {

  /// Indicates the name of the program.
  /// This is dependent on the current localization of the referenced program, and is suitable for presentation to the user.
  public var localizedName: String = ""

  /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
  public var bundleURL: URL?

  /// Indicates the URL to the application's executable.
  public var executableURL: URL?

  /// Indicates the icon TIFF representation data of the application.
  public var iconTIFFRepresentation: Data?

  package init(
    localizedName: String = "",
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

@available(SwiftStdlib 6.0, *)
extension Program: Identifiable {
  public var id: String { persistentModelID }

  public var persistentModelID: String { localizedName }
}

@available(SwiftStdlib 6.0, *)
extension Program {

  public typealias Model = V1._Program

  public init(persistentModel: Model) {
    localizedName = persistentModel.localizedName
    bundleURL = persistentModel.bundleURL
    executableURL = persistentModel.executableURL
    iconTIFFRepresentation = persistentModel.iconTIFFRepresentation
  }
}
