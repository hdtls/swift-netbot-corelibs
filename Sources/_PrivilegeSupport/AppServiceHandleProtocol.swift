//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import ServiceManagement

  /// AppServiceHandleProtocol is the NSXPCConnection-based protocol implemented by the XPC service and called by the app.
  ///
  /// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
  @available(SwiftStdlib 5.3, *)
  @objc public protocol AppServiceHandleProtocol: Sendable {

    /// Connection code signing requirement.
    func codeSigningRequirement() async -> String

    /// Initializes an app service object with a launch daemon with the property list name you provide and register the service.
    func register(daemon plistName: String) async throws

    /// Initializes an app service object with a launch agent with the property list name you provide and register the service.
    func register(agent plistName: String) async throws

    /// Initializes an app service object for a login item corresponding to the bundle with the identifier you provide and register the service.
    func register(loginItem identifier: String) async throws

    /// Unregister the app service object for a launch daemon initialized with the property list name you provide.
    func unregister(daemon plistName: String) async throws

    /// Unregister the app service object for a launch agent initialized with the property list name you provide.
    func unregister(agent plistName: String) async throws

    /// Unregister the app service object for a login item initialized with the identifier you provide.
    func unregister(loginItem identifier: String) async throws

    /// Return status of the app service object for a launch daemon initialized with the identifier you provide.
    @available(macOS 13.0, *)
    func status(daemon plistName: String) async -> SMAppService.Status

    /// Return status of the app service object for a launch agent initialized with the identifier you provide.
    @available(macOS 13.0, *)
    func status(agent plistName: String) async -> SMAppService.Status

    /// Return status of the app service object for a login item initialized with the identifier you provide.
    @available(macOS 13.0, *)
    func status(loginItem identifier: String) async -> SMAppService.Status

    /// Opens System Settings to the Login Items control panel.
    @available(macOS 13.0, *)
    func openSystemSettingsLoginItems() async

    /// Called by the app to get an endpoint that's connected to the helper tool.
    func connect(matchService name: String) async throws -> NSXPCListenerEndpoint

    /// Called by the app at startup time to set up our authorization rights in the
    /// authorization database.
    func setupAuthorizationRights() async throws

    /// Returns the XPC service's authorization reference so that
    /// the app can pass that to the requests it sends to the helper tool.
    /// Without this authorization request to helper tool will fail because the app is sandboxed.
    func authorizationExternalForm() async throws -> Data
  }
#endif
