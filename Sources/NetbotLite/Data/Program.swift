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

/// Information about an application and its associated activity.
///
/// ``Program`` stores metadata describing an application, including its
/// name, bundle location, executable, icon, and aggregated reporting data.
///
/// Use this type to associate network activity and data transfer metrics
/// with a specific application.
///
/// Use ``Program`` when working with programs in memory.
/// Use ``V1/Program`` when storing program data.
///
/// - SeeAlso: ``V1/Program``
@available(SwiftStdlib 6.0, *)
public struct Program: Hashable, Codable, Sendable {

  /// The localized display name of the application.
  ///
  /// This value is intended for presentation to users and may vary
  /// depending on the current locale.
  public var localizedName: String

  /// The URL of the application's bundle.
  ///
  /// This value identifies the bundle package that contains the
  /// application's resources and executable.
  public var bundleURL: URL?

  /// The URL of the application's executable.
  ///
  /// This value identifies the executable file launched by the system.
  public var executableURL: URL?

  /// The application's icon in TIFF format.
  ///
  /// This value contains the raw TIFF representation of the application's
  /// icon and may be used to recreate an image for display purposes.
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

  /// In used persistent model typealias.
  public typealias Model = V1.Program

  /// Create a new ``Program`` from persistent program.
  /// - Parameter persistentModel: Persistent prgram.
  public init(persistentModel: Model) {
    localizedName = persistentModel.localizedName
    bundleURL = persistentModel.bundleURL
    executableURL = persistentModel.executableURL
    iconTIFFRepresentation = persistentModel.iconTIFFRepresentation
  }
}
