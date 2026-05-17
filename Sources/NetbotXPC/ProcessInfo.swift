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
  import Foundation
  import SynchronizationExtras

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Lockable public class ProcessInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app, and is suitable for presentation to the user.
    public var processName: String?

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    public var processBundleURL: URL?

    /// Indicates the URL to the application's executable.
    public var processExecutableURL: URL?

    /// Indicates the process identifier (pid) of the application.
    public var processIdentifier: Int32?

    /// Indicates the icon TIFF representation data of the application.
    public var processIconTIFFRepresentation: Data?

    private enum CodingKeys: String {
      case processName
      case processBundleURL
      case processExecutableURL
      case processIdentifier
      case processIconTIFFRepresentation
    }

    public override init() {
      self._processName = .init(nil)
      self._processBundleURL = .init(nil)
      self._processExecutableURL = .init(nil)
      self._processIdentifier = .init(nil)
      self._processIconTIFFRepresentation = .init(nil)
    }

    public required init?(coder: NSCoder) {
      self._processName = .init(
        coder.decodeObject(of: NSString.self, forKey: CodingKeys.processName.rawValue) as String?)
      self._processBundleURL = .init(
        coder.decodeObject(of: NSURL.self, forKey: CodingKeys.processBundleURL.rawValue) as URL?)
      self._processExecutableURL = .init(
        coder.decodeObject(of: NSURL.self, forKey: CodingKeys.processExecutableURL.rawValue) as URL?
      )
      self._processIdentifier = .init(
        coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.processIdentifier.rawValue)?
          .int32Value)
      self._processIconTIFFRepresentation = .init(
        coder.decodeObject(
          of: NSData.self, forKey: CodingKeys.processIconTIFFRepresentation.rawValue) as Data?)
    }

    public func encode(with coder: NSCoder) {
      coder.encode(processName, forKey: CodingKeys.processName.rawValue)
      coder.encode(processBundleURL, forKey: CodingKeys.processBundleURL.rawValue)
      coder.encode(processExecutableURL, forKey: CodingKeys.processExecutableURL.rawValue)
      coder.encode(processIdentifier, forKey: CodingKeys.processIdentifier.rawValue)
      coder.encode(
        processIconTIFFRepresentation, forKey: CodingKeys.processIconTIFFRepresentation.rawValue)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension ProcessInfo: @unchecked Sendable {}
#endif
