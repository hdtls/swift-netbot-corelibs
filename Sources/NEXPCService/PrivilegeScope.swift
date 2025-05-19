//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import ServiceManagement
  import os

  // swift-format-ignore: AlwaysUseLowerCamelCase
  public var PHT: PrivilegeScope { PrivilegeScope.shared }

  @globalActor public actor PrivilegeScope {

    public static let shared = PrivilegeScope()

    private var authorizationExternalForm: Data?

    private var privileges: NSXPCConnection!
    private var tc: NSXPCConnection!

    public let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.apple.xpc")

    /// Ensures that we're connected to our XPC service.
    private func setAppServiceHandleIfNeeded() async throws {
      guard privileges == nil else {
        return
      }
      let privileges = NSXPCConnection(serviceName: "com.tenbits.netbot.privileges")
      privileges.remoteObjectInterface = NSXPCInterface(with: (any AppServiceHandleProtocol).self)

      // We can ignore the retain cycle warning because the retain taken by the
      // invalidation handler block is released by us setting it to nil when the block
      // actually runs.
      privileges.invalidationHandler = {
        // If the connection gets invalidated then, on the main thread, nil out our
        // reference to it.  This ensures that we attempt to rebuild it the next time around.
        Task {
          self.privileges.invalidationHandler = nil
          self.privileges = nil
        }
        self.logger.debug("Service com.tenbits.netbot.privileges connection invalidated")
      }
      self.privileges = privileges
      privileges.activate()

      try await self.privileges.remoteAppServiceHandle().setupAuthorizationRights()
    }

    /// Ensures that we're connected to our helper tool service.
    private func setToolIfNeeded() async throws {
      guard tc == nil else {
        return
      }

      // There's no helper tool connection in place.  Create on XPC service and ask
      // it to give us an endpoint for the helper tool.
      try await setAppServiceHandleIfNeeded()
      let proxy = try privileges.remoteAppServiceHandle()
      let endpoint = try await proxy.connect(matchService: "com.tenbits.netbot.sbd")

      // The XPC service gave us an endpoint for the helper tool.  Create a connection from that.
      // Also, save the authorization information returned by the helper tool so that the command
      // block can send requests that act like they're coming from the XPC service (which is allowed
      // to use authorization services) and not the app (which isn't, because it's sandboxed).
      tc = NSXPCConnection(listenerEndpoint: endpoint)
      tc.remoteObjectInterface = NSXPCInterface(with: (any PHTHandleProtocol).self)

      // We can ignore the retain cycle warning because the retain taken by the
      // invalidation handler block is released by us setting it to nil when the block
      // actually runs.
      tc.invalidationHandler = {
        // If the connection gets invalidated then, on the main thread, nil out our
        // reference to it.  This ensures that we attempt to rebuild it the next time around.
        Task {
          self.tc.invalidationHandler = nil
          self.tc = nil
        }
        self.logger.debug("Service com.tenbits.netbot.sbd connection invalidated")
      }
      tc.activate()

      authorizationExternalForm = try await proxy.authorizationExternalForm()
    }

    /// Activate helper tool launch daemon.
    ///
    /// Call this function to register helper tool.
    public func activate() async throws {
      let plistName = "com.tenbits.netbot.sbd.plist"

      do {
        try await setAppServiceHandleIfNeeded()
        let proxy = try privileges.remoteAppServiceHandle()
        if case .enabled = await proxy.status(daemon: plistName) {
          return
        }
        try await proxy.register(daemon: plistName)
      } catch {
        self.logger.error("Launch daemon \(plistName) register failure with error: \(error)")
        throw error
      }
    }

    /// Invalidate helper tool launch daemon.
    ///
    /// Call this function to unregister helper tool.
    public func invalidate() async throws {
      try await setAppServiceHandleIfNeeded()

      let plistName = "com.tenbits.netbot.sbd.plist"

      do {
        let proxy = try privileges.remoteAppServiceHandle()
        guard case .enabled = await proxy.status(daemon: plistName) else {
          return
        }
        try await proxy.unregister(daemon: plistName)
      } catch {
        self.logger.error("Launch daemon \(plistName) unregister failure with error: \(error)")
        throw error
      }
    }

    /// Connects to the helper tool and execute operation within connected tool handle and access token.
    ///
    /// Calling this function will automatically register launch daemon if needed.
    @discardableResult
    private func submit<Value>(
      execute: @escaping @Sendable (any PHTHandleProtocol, Data) async throws -> Value
    )
      async throws -> Value where Value: Sendable
    {
      // Always request register service to make sure we can connect to the service.
      try await activate()

      // Ensure that we have helper tool connected.
      try await setToolIfNeeded()

      // The helper tool connection is already in place
      let tool = try tc.remotePHTHandle()

      // We also pass authorization data to block, because some of tool request require authorization.
      if authorizationExternalForm == nil {
        authorizationExternalForm = try await privileges.remoteAppServiceHandle()
          .authorizationExternalForm()
      }

      // The helper tool and authorization data is here, so we can just call the
      // command block directly.
      return try await execute(tool, authorizationExternalForm!)
    }

    public func toolVersion() async throws -> String {
      try await submit { tool, _ in
        await tool.toolVersion()
      }
    }

    public func setNWProtocolProxies(processName: String, options: NEProtocolProxies.Options)
      async throws
    {
      try await submit { tool, _ in
        try await tool.setNWProtocolProxies(processName: processName, options: options)
      }
    }
  }

  extension NSXPCConnection {

    /// Convert `remoteObjectProxy` to `any AppServiceHandleProtocol` if possible.
    ///
    /// Throw operationUnsupported if remote object proxy is not a `any AppServiceHandleProtocol` object, or
    /// error that `remoteObjectProxyWithErrorHandler` throws.
    func remoteAppServiceHandle() throws -> any AppServiceHandleProtocol {
      try remoteObjectProxy(as: (any AppServiceHandleProtocol).self)
    }
  }
#endif
