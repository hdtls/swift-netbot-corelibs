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
  import ServiceManagement
  import Logging

  @available(SwiftStdlib 6.0, *)
  enum ServiceName: String {
    case assistantService = "com.tenbits.netbot.AssistantService"
    case assistantd = "com.tenbits.netbot.assistantd"
  }

  @available(SwiftStdlib 6.0, *)
  @globalActor public actor PHTSession {

    public static let shared = PHTSession()

    private var authorizationExternalForm: Data?

    private var assistantService: NSXPCConnection!
    private var assistantd: NSXPCConnection!
    private var isActive = false

    public let logger = Logger(label: "PHT")

    /// Ensures that we're connected to our XPC service.
    private func setAssistantServiceIfNeeded() async throws {
      guard assistantService == nil else {
        return
      }
      assistantService = NSXPCConnection(serviceName: ServiceName.assistantService.rawValue)
      assistantService.remoteObjectInterface = NSXPCInterface(
        with: (any AppServiceHandleProtocol).self)

      // We can ignore the retain cycle warning because the retain taken by the
      // invalidation handler block is released by us setting it to nil when the block
      // actually runs.
      assistantService.invalidationHandler = {
        // If the connection gets invalidated then, on the main thread, nil out our
        // reference to it.  This ensures that we attempt to rebuild it the next time around.
        Task {
          self.assistantService.invalidationHandler = nil
          self.assistantService = nil
        }
        self.logger.debug(
          "Connection to service \(ServiceName.assistantService.rawValue) invalidated")
      }
      assistantService.activate()
      logger.debug("Connection to service \(ServiceName.assistantService.rawValue) activated")

      try await assistantService.assistantService().setupAuthorizationRights()
    }

    /// Ensures that we're connected to our helper tool service.
    private func setAssistantdIfNeeded() async throws {
      guard assistantd == nil else {
        return
      }

      // There's no helper tool connection in place.  Create on XPC service and ask
      // it to give us an endpoint for the helper tool.
      try await setAssistantServiceIfNeeded()
      let proxy = try assistantService.assistantService()
      let endpoint = try await proxy.connect(matchService: ServiceName.assistantd.rawValue)
      logger.debug(
        "Service \(ServiceName.assistantService.rawValue) successfully connected to daemon \(ServiceName.assistantd.rawValue)"
      )
      // The XPC service gave us an endpoint for the helper tool.  Create a connection from that.
      // Also, save the authorization information returned by the helper tool so that the command
      // block can send requests that act like they're coming from the XPC service (which is allowed
      // to use authorization services) and not the app (which isn't, because it's sandboxed).
      assistantd = NSXPCConnection(listenerEndpoint: endpoint)
      assistantd.remoteObjectInterface = NSXPCInterface(with: (any PHTHandleProtocol).self)

      // We can ignore the retain cycle warning because the retain taken by the
      // invalidation handler block is released by us setting it to nil when the block
      // actually runs.
      assistantd.invalidationHandler = {
        // If the connection gets invalidated then, on the main thread, nil out our
        // reference to it.  This ensures that we attempt to rebuild it the next time around.
        Task {
          self.assistantd.invalidationHandler = nil
          self.assistantd = nil
        }
        self.logger.debug("Connection to daemon \(ServiceName.assistantd.rawValue) invalidated")
      }
      assistantd.activate()
      logger.debug("Connection to daemon \(ServiceName.assistantd.rawValue) activated")
      authorizationExternalForm = try await proxy.authorizationExternalForm()
    }

    /// Activate privileged helper.
    ///
    /// Call this function to register helper tool.
    public func activate() async throws {
      guard !isActive else { return }

      let plistName = "\(ServiceName.assistantd.rawValue).plist"

      try await setAssistantServiceIfNeeded()
      let proxy = try assistantService.assistantService()

      do {
        let errorDomain =
          if #available(SwiftStdlib 6.0, *) {
            SMAppServiceErrorDomain
          } else {
            "SMAppServiceErrorDomain"
          }

        try await proxy.register(daemon: plistName)

        let status = await proxy.status(daemon: plistName)

        switch status {
        case .notRegistered:
          try await proxy.register(daemon: plistName)
          guard case .enabled = await proxy.status(daemon: plistName) else {
            throw NSError(
              domain: errorDomain,
              code: kSMErrorLaunchDeniedByUser,
              userInfo: [
                NSLocalizedDescriptionKey:
                  "Launch daemon \(plistName) has been successfully registered, but we need take action in System Settings before the service is eligible to run"
              ]
            )
          }
          isActive = true
          logger.debug("Daemon \(plistName) is activated")
        case .enabled:
          isActive = true
        case .requiresApproval:
          throw NSError(
            domain: errorDomain,
            code: kSMErrorLaunchDeniedByUser,
            userInfo: [
              NSLocalizedDescriptionKey:
                "Launch daemon \(plistName) has been successfully registered, but we need take action in System Settings before the service is eligible to run"
            ]
          )
        case .notFound:
          throw NSError(
            domain: errorDomain,
            code: kSMErrorJobNotFound,
            userInfo: [NSLocalizedDescriptionKey: "Launch daemon \(plistName) not found"]
          )
        @unknown default:
          throw NSError(
            domain: errorDomain,
            code: kSMErrorInternalFailure,
            userInfo: [
              NSLocalizedDescriptionKey:
                "Launch daemon \(plistName) run into unhandled @unknown default status"
            ]
          )
        }
      } catch {
        logger.error("Daemon \(plistName) failed to activated \(error)")
        throw error
      }
    }

    /// Invalidate helper tool launch daemon.
    ///
    /// Call this function to unregister helper tool.
    public func invalidate() async throws {
      guard isActive else { return }
      isActive = false

      try await setAssistantServiceIfNeeded()

      let plistName = "\(ServiceName.assistantd.rawValue).plist"

      do {
        let proxy = try assistantService.assistantService()
        guard case .enabled = await proxy.status(daemon: plistName) else {
          return
        }
        try await proxy.unregister(daemon: plistName)
        logger.debug("Daemon \(ServiceName.assistantd.rawValue) successfully unregistered")
      } catch {
        logger.error("Daemon \(ServiceName.assistantd.rawValue) failed to unregister \(error)")
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
      try await setAssistantdIfNeeded()

      // The helper tool connection is already in place
      let tool = try assistantd.assistantd()

      // We also pass authorization data to block, because some of tool request require authorization.
      if authorizationExternalForm == nil {
        authorizationExternalForm = try await assistantService.assistantService()
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

    /// Update system proxy settings using specify options.
    ///
    /// This function is called by daemons to set the system proxy settings,
    /// including web proxy secury web proxy and socks proxy. It is not
    /// necessary to call this function with nil to clear out the existing
    /// settings before calling this function with a non-nil configuration.
    ///
    public func setNWProtocolProxies(processName: String, options: NEProxySettings?)
      async throws
    {
      try await submit { tool, _ in
        try await tool.setNWProtocolProxies(processName: processName, options: options)
      }
    }

    public func processInfo(address: UInt16) async throws -> ProcessInfo? {
      try await submit { tool, _ in
        try await tool.processInfo(address: address)
      }
    }
  }

  @available(SwiftStdlib 6.0, *)
  extension NSXPCConnection {

    /// Convert `remoteObjectProxy` to `any AppServiceHandleProtocol` if possible.
    ///
    /// Throw operationUnsupported if remote object proxy is not a `any AppServiceHandleProtocol` object, or
    /// error that `remoteObjectProxyWithErrorHandler` throws.
    func assistantService() throws -> any AppServiceHandleProtocol {
      try remoteObjectProxy(as: (any AppServiceHandleProtocol).self)
    }
  }
#endif
