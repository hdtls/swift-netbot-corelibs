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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public class NEProxyServer: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public var address: String {
      get { _lock.withLock { _address } }
      set { _lock.withLock { _address = newValue } }
    }
    private var _address: String

    public var port: Int {
      get { _lock.withLock { _port } }
      set { _lock.withLock { _port = newValue } }
    }
    private var _port: Int

    public var authenticationRequired: Bool {
      get { _lock.withLock { _authenticationRequired } }
      set { _lock.withLock { _authenticationRequired = newValue } }
    }
    private var _authenticationRequired = false

    public var username: String? {
      get { _lock.withLock { _username } }
      set { _lock.withLock { _username = newValue } }
    }
    private var _username: String?

    public var password: String? {
      get { _lock.withLock { _password } }
      set { _lock.withLock { _password = newValue } }
    }
    private var _password: String?

    private let _lock = NSLock()

    public init(address: String, port: Int) {
      self._address = address
      self._port = port
    }

    private enum CodingKeys: String {
      case address
      case port
      case authenticationRequired
      case username
      case password
    }

    public required init?(coder: NSCoder) {
      _address =
        coder.decodeObject(of: NSString.self, forKey: CodingKeys.address.rawValue) as String?
        ?? ""
      _port = coder.decodeInteger(forKey: CodingKeys.port.rawValue)
      _authenticationRequired = coder.decodeBool(forKey: CodingKeys.authenticationRequired.rawValue)
      _username =
        coder.decodeObject(of: NSString.self, forKey: CodingKeys.username.rawValue) as String?
      _password =
        coder.decodeObject(of: NSString.self, forKey: CodingKeys.password.rawValue) as String?
    }

    public func encode(with coder: NSCoder) {
      coder.encode(address, forKey: CodingKeys.address.rawValue)
      coder.encode(port, forKey: CodingKeys.port.rawValue)
      coder.encode(authenticationRequired, forKey: CodingKeys.authenticationRequired.rawValue)
      coder.encode(username, forKey: CodingKeys.username.rawValue)
      coder.encode(password, forKey: CodingKeys.password.rawValue)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension NEProxyServer: @unchecked Sendable {}
#endif
