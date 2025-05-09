//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Foundation
  import ServiceManagement
  import os

  @available(macOS 13.0, *)
  @globalActor public actor PrivilegeScope {

    public static let shared = PrivilegeScope()

    private var authorization: Data?

    private var privileges: NSXPCConnection!
    private var tc: NSXPCConnection!

    public let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.apple.xpc")

    private init() {
      var extForm = AuthorizationExternalForm()

      // Create our connection to the authorization system.
      //
      // If we can't create an authorization reference then the app is not going to be able
      // to do anything requiring authorization.  Generally this only happens when you launch
      // the app in some wacky, and typically unsupported, way.  In the debug build we flag that
      // with an assert.  In the release build we continue with self->_authRef as NULL, which will
      // cause all authorized operations to fail.

      var authorizationRef: AuthorizationRef?
      var err = AuthorizationCreate(nil, nil, .init(rawValue: 0), &authorizationRef)
      if err == errAuthorizationSuccess {
        err = AuthorizationMakeExternalForm(authorizationRef!, &extForm)
      }
      assert(err == errAuthorizationSuccess)
      assert(authorizationRef != nil)
    }

    /// Activate helper tool launch daemon.
    ///
    /// Call this function to register helper tool.
    public func activate() async throws {
      let plistName = "com.tenbits.netbot.sbd.plist"

      do {
        try await setPrivilegesIfNeeded()
        let proxy = try privileges.service()
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
      try await setPrivilegesIfNeeded()

      let plistName = "com.tenbits.netbot.sbd.plist"

      do {
        let proxy = try privileges.service()
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
    public func submit<Value>(
      execute: @escaping @Sendable (any HelperToolHandleProtocol, Data) async throws -> Value
    )
      async throws -> Value where Value: Sendable
    {
      // Always request register service to make sure we can connect to the service.
      try await activate()

      // Ensure that we have helper tool connected.
      try await setToolIfNeeded()

      // The helper tool connection is already in place
      let tool = try tc.tool()

      // We also pass authorization data to block, because some of tool request require authorization.
      if authorization == nil {
        authorization = try await privileges.service().authorization()
      }

      // The helper tool and authorization data is here, so we can just call the
      // command block directly.
      return try await execute(tool, authorization!)
    }

    public func toolVersion() async throws -> String {
      try await submit { tool, _ in
        await tool.toolVersion()
      }
    }

    /// Ensures that we're connected to our XPC service.
    private func setPrivilegesIfNeeded() async throws {
      guard privileges == nil else {
        return
      }
      let privileges = NSXPCConnection(serviceName: "com.tenbits.netbot.privileges")
      privileges.remoteObjectInterface = NSXPCInterface(with: (any XPCServiceHandleProtocol).self)

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

      try await self.privileges.service().setupAuthorizationRights()
    }

    /// Ensures that we're connected to our helper tool service.
    private func setToolIfNeeded() async throws {
      guard tc == nil else {
        return
      }

      // There's no helper tool connection in place.  Create on XPC service and ask
      // it to give us an endpoint for the helper tool.
      try await setPrivilegesIfNeeded()
      let proxy = try privileges.service()
      let endpoint = try await proxy.connect(matchService: "com.tenbits.netbot.sbd")

      // The XPC service gave us an endpoint for the helper tool.  Create a connection from that.
      // Also, save the authorization information returned by the helper tool so that the command
      // block can send requests that act like they're coming from the XPC service (which is allowed
      // to use authorization services) and not the app (which isn't, because it's sandboxed).
      tc = NSXPCConnection(listenerEndpoint: endpoint)
      tc.remoteObjectInterface = NSXPCInterface(with: (any HelperToolHandleProtocol).self)

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

      authorization = try await proxy.authorization()
    }
  }
#endif
