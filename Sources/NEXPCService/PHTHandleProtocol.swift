//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation

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

  extension NEProxyServer: @unchecked Sendable {}

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

    var options: [CFString: Any] {
      [
        kCFNetworkProxiesHTTPEnable: httpEnabled ? 1 : 0,
        kCFNetworkProxiesHTTPProxy: httpsServer?.address as Any,
        kCFNetworkProxiesHTTPPort: httpServer?.port as Any,
        kCFNetworkProxiesHTTPSEnable: httpEnabled ? 1 : 0,
        kCFNetworkProxiesHTTPSProxy: httpsServer?.address as Any,
        kCFNetworkProxiesHTTPSPort: httpsServer?.port as Any,
        kCFNetworkProxiesSOCKSEnable: socksEnabled ? 1 : 0,
        kCFNetworkProxiesSOCKSProxy: socksServer?.address as Any,
        kCFNetworkProxiesSOCKSPort: socksServer?.port as Any,
        kCFNetworkProxiesExcludeSimpleHostnames: excludeSimpleHostnames ? 1 : 0,
        kCFNetworkProxiesExceptionsList: exceptionList as Any,
      ]
    }

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

  extension NEProxySettings: @unchecked Sendable {}

  public class NEProtocolProxies {
    public typealias Options = NEProxySettings
  }

  /// PHTHandleProtocol is the NSXPCConnection-based protocol implemented by the helper tool
  /// and called by the app.
  @objc public protocol PHTHandleProtocol: Sendable {

    /// Not used by the standard app (it's part of the sandboxed XPC service support).
    func listenerEndpoint() async -> NSXPCListenerEndpoint

    /// Returns the version number of the tool.
    ///
    /// - Note: This operation never requires authorization.
    func toolVersion() async -> String

    /// Configure system network proxies for Wi-Fi and Ethernet.
    ///
    /// - Parameters:
    ///   - processName: A string that describes the name of the calling process.
    ///   - options: Options for system network proxies.
    func setNWProtocolProxies(processName: String, options: NEProtocolProxies.Options) async throws
  }
#endif
