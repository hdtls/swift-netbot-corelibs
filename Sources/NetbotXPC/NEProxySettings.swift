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

#if canImport(NetworkExtension)
  import Foundation
  import NetworkExtension

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public class NEProxySettings: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public var httpEnabled: Bool {
      get { _lock.withLock { _httpEnabled } }
      set { _lock.withLock { _httpEnabled = newValue } }
    }
    private var _httpEnabled = false

    public var httpServer: NEProxyServer? {
      get { _lock.withLock { _httpServer } }
      set { _lock.withLock { _httpServer = newValue } }
    }
    private var _httpServer: NEProxyServer?

    public var httpsEnabled: Bool {
      get { _lock.withLock { _httpsEnabled } }
      set { _lock.withLock { _httpsEnabled = newValue } }
    }
    private var _httpsEnabled = false

    public var httpsServer: NEProxyServer? {
      get { _lock.withLock { _httpsServer } }
      set { _lock.withLock { _httpsServer = newValue } }
    }
    private var _httpsServer: NEProxyServer?

    public var socksEnabled: Bool {
      get { _lock.withLock { _socksEnabled } }
      set { _lock.withLock { _socksEnabled = newValue } }
    }
    private var _socksEnabled = false

    public var socksServer: NEProxyServer? {
      get { _lock.withLock { _socksServer } }
      set { _lock.withLock { _socksServer = newValue } }
    }
    private var _socksServer: NEProxyServer?

    public var excludeSimpleHostnames: Bool {
      get { _lock.withLock { _excludeSimpleHostnames } }
      set { _lock.withLock { _excludeSimpleHostnames = newValue } }
    }
    private var _excludeSimpleHostnames = false

    public var exceptionList: [String]? {
      get { _lock.withLock { _exceptionList } }
      set { _lock.withLock { _exceptionList = newValue } }
    }
    private var _exceptionList: [String]?

    private let _lock = NSLock()

    private enum CodingKeys: String {
      case httpEnabled
      case httpServer
      case httpsEnabled
      case httpsServer
      case socksEnabled
      case socksServer
      case excludeSimpleHostnames
      case exceptionList
    }

    public override init() {}

    public required init?(coder: NSCoder) {
      _httpEnabled = coder.decodeBool(forKey: CodingKeys.httpEnabled.rawValue)
      _httpServer = coder.decodeObject(
        of: NEProxyServer.self, forKey: CodingKeys.httpServer.rawValue)
      _httpsEnabled = coder.decodeBool(forKey: CodingKeys.httpsEnabled.rawValue)
      _httpsServer = coder.decodeObject(
        of: NEProxyServer.self, forKey: CodingKeys.httpsServer.rawValue)
      _socksEnabled = coder.decodeBool(forKey: CodingKeys.socksEnabled.rawValue)
      _socksServer = coder.decodeObject(
        of: NEProxyServer.self, forKey: CodingKeys.socksServer.rawValue)
      _excludeSimpleHostnames = coder.decodeBool(forKey: CodingKeys.excludeSimpleHostnames.rawValue)
      _exceptionList =
        coder.decodeArrayOfObjects(
          ofClasses: [NSString.self], forKey: CodingKeys.exceptionList.rawValue) as? [String]
    }

    public func encode(with coder: NSCoder) {
      coder.encode(httpEnabled, forKey: CodingKeys.httpEnabled.rawValue)
      coder.encode(httpServer, forKey: CodingKeys.httpServer.rawValue)
      coder.encode(httpsEnabled, forKey: CodingKeys.httpsEnabled.rawValue)
      coder.encode(httpsServer, forKey: CodingKeys.httpsServer.rawValue)
      coder.encode(socksEnabled, forKey: CodingKeys.socksEnabled.rawValue)
      coder.encode(socksServer, forKey: CodingKeys.socksServer.rawValue)
      coder.encode(excludeSimpleHostnames, forKey: CodingKeys.excludeSimpleHostnames.rawValue)
      coder.encode(exceptionList, forKey: CodingKeys.exceptionList.rawValue)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension NEProxySettings: @unchecked Sendable {}

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension Optional where Wrapped == NEProxySettings {

    var options: [CFString: Any] {
      switch self {
      case .none:
        return [
          kCFNetworkProxiesHTTPEnable: 0,
          kCFNetworkProxiesHTTPSEnable: 0,
          kCFNetworkProxiesSOCKSEnable: 0,
          kCFNetworkProxiesExcludeSimpleHostnames: 0,
          kCFNetworkProxiesExceptionsList: [],
        ]
      case .some(let wrapped):
        var options: [CFString: Any] = [:]
        options[kCFNetworkProxiesHTTPEnable] = wrapped.httpEnabled ? 1 : 0
        options[kCFNetworkProxiesHTTPProxy] = wrapped.httpsServer?.address
        options[kCFNetworkProxiesHTTPPort] = wrapped.httpServer?.port
        options[kCFNetworkProxiesHTTPSEnable] = wrapped.httpEnabled ? 1 : 0
        options[kCFNetworkProxiesHTTPSProxy] = wrapped.httpsServer?.address
        options[kCFNetworkProxiesHTTPSPort] = wrapped.httpsServer?.port
        options[kCFNetworkProxiesSOCKSEnable] = wrapped.socksEnabled ? 1 : 0
        options[kCFNetworkProxiesSOCKSProxy] = wrapped.socksServer?.address
        options[kCFNetworkProxiesSOCKSPort] = wrapped.socksServer?.port
        options[kCFNetworkProxiesExcludeSimpleHostnames] = wrapped.excludeSimpleHostnames ? 1 : 0
        options[kCFNetworkProxiesExceptionsList] = wrapped.exceptionList
        return options
      }
    }
  }
#endif
