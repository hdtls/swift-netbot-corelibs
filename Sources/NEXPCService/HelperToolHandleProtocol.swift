//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation

  @available(macOS 13.0, *)
  @objc public protocol AuthorizationHandleProtocol: Sendable {

    /// Require authorization rights for modify system VPN settings.
    func systemVPNAuthorizationRights(authentication: Data) async throws -> Data

    /// Require authorization rights for modify system proxy settings.
    func systemNetworkingAuthorizationRights(authentication: Data) async throws -> Data
  }

  /// HelperToolHandleProtocol is the NSXPCConnection-based protocol implemented by the helper tool
  /// and called by the app.
  @available(macOS 13.0, *)
  @objc public protocol HelperToolHandleProtocol: AuthorizationHandleProtocol {

    /// Not used by the standard app (it's part of the sandboxed XPC service support).
    func listenerEndpoint() async -> NSXPCListenerEndpoint

    /// Returns the version number of the tool.
    ///
    /// - Note: This operation never requires authorization.
    func toolVersion() async -> String
  }
#endif
