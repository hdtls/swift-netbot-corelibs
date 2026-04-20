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
  import Foundation

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public class ProcessInfo: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app, and is suitable for presentation to the user.
    public var processName: String? {
      get { _lock.withLock { _processName } }
      set { _lock.withLock { _processName = newValue } }
    }
    private var _processName: String?

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    public var processBundleURL: URL? {
      get { _lock.withLock { _processBundleURL } }
      set { _lock.withLock { _processBundleURL = newValue } }
    }
    private var _processBundleURL: URL?

    /// Indicates the URL to the application's executable.
    public var processExecutableURL: URL? {
      get { _lock.withLock { _processExecutableURL } }
      set { _lock.withLock { _processExecutableURL = newValue } }
    }
    private var _processExecutableURL: URL?

    /// Indicates the process identifier (pid) of the application.
    public var processIdentifier: Int32? {
      get { _lock.withLock { _processIdentifier } }
      set { _lock.withLock { _processIdentifier = newValue } }
    }
    private var _processIdentifier: Int32?

    /// Indicates the icon TIFF representation data of the application.
    public var processIconTIFFRepresentation: Data? {
      get { _lock.withLock { _processIconTIFFRepresentation } }
      set { _lock.withLock { _processIconTIFFRepresentation = newValue } }
    }
    private var _processIconTIFFRepresentation: Data?

    private let _lock = NSLock()

    private enum CodingKeys: String {
      case processName
      case processBundleURL
      case processExecutableURL
      case processIdentifier
      case processIconTIFFRepresentation
    }

    public override init() {}

    public required init?(coder: NSCoder) {
      _processName =
        coder.decodeObject(of: NSString.self, forKey: CodingKeys.processName.rawValue) as String?
      _processBundleURL =
        coder.decodeObject(of: NSURL.self, forKey: CodingKeys.processBundleURL.rawValue) as URL?
      _processExecutableURL =
        coder.decodeObject(of: NSURL.self, forKey: CodingKeys.processExecutableURL.rawValue) as URL?
      _processIdentifier =
        coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.processIdentifier.rawValue)?
        .int32Value
      _processIconTIFFRepresentation =
        coder.decodeObject(
          of: NSData.self, forKey: CodingKeys.processIconTIFFRepresentation.rawValue) as Data?
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension ProcessInfo: @unchecked Sendable {}
#endif
