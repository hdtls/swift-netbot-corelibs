//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if os(macOS)
  import Foundation
  import ServiceManagement
  import os

  /// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the
  /// service to make it available to the process hosting the service over an NSXPCConnection.
  @available(SwiftStdlib 5.3, *)
  final public class AppServiceHandle {

    private let authorizationExternalForm: Data

    /// only accessed or modified by operations on self.queue
    private var connection: NSXPCConnection!
    private let lock = NSLock()

    private var authorizationRef: AuthorizationRef?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.apple.xpc")

    public init() {
      var err = errAuthorizationSuccess
      var extForm = AuthorizationExternalForm()

      err = AuthorizationCreate(nil, nil, .init(rawValue: 0), &authorizationRef)
      if err == errAuthorizationSuccess, let authorizationRef {
        err = AuthorizationMakeExternalForm(authorizationRef, &extForm)
      }
      if err == errAuthorizationSuccess {
        authorizationExternalForm = withUnsafeBytes(of: &extForm) { Data($0) }
      } else {
        authorizationExternalForm = Data()
      }
      assert(err == errAuthorizationSuccess)
    }

    deinit {
      if let authorizationRef {
        AuthorizationFree(authorizationRef, .init(rawValue: 0))
      }
    }

    @available(SwiftStdlib 5.7, *)
    private func register(plistName: String, service: SMAppService) async throws {
      do {
        let status = service.status
        try service.register()
        switch status {
        case .notRegistered:
          try service.register()
        case .enabled:
          logger.debug(
            "Launch service \(plistName) already enabled"
          )
        case .requiresApproval:
          // Replace throw error with open system settings login items panel.
          logger.debug(
            "Launch service \(plistName) has been successfully registered, but we need take action in System Settings before the service is eligible to run"
          )
          SMAppService.openSystemSettingsLoginItems()
        case .notFound:
          try service.register()
        @unknown default:
          throw NSError(
            domain: "SMAppServiceDomain", code: -1,
            userInfo: [
              NSLocalizedFailureErrorKey:
                "Launch service \(plistName) run into unhandled @unknown default status"
            ])
        }
      } catch {
        switch service.status {
        case .enabled:
          // How it is possible for service that register failed and become enabled at the same time.
          break
        case .notFound:
          logger.error("Launch service \(plistName) not found")
          throw error
        case .notRegistered:
          logger.error("Launch service \(plistName) register failure with error: \(error)")
          throw error
        case .requiresApproval:
          // Replace throw error with open system settings login items panel.
          logger.debug(
            "Launch service \(plistName) has been successfully registered, but we need take action in System Settings before the service is eligible to run"
          )
          SMAppService.openSystemSettingsLoginItems()
        @unknown default:
          logger.fault("Launch service \(plistName) run into unhandled @unknown default status")
          throw error
        }
      }
    }

    @available(SwiftStdlib 5.7, *)
    private func unregister(plistName: String, service: SMAppService) async throws {
      do {
        try await SMAppService.daemon(plistName: plistName).unregister()
        logger.debug("Launch service \(plistName) has been successfully unregistered")
      } catch {
        logger.error("Launch service \(plistName) unregister failure with error: \(error)")
        throw error
      }
    }

    private func connect0(matchService name: String) {
      lock.withLock {
        // Because we access connection, we have to run on the operation queue.
        guard connection == nil else {
          return
        }

        connection = NSXPCConnection(machServiceName: name, options: .privileged)
        connection?.remoteObjectInterface = NSXPCInterface(with: (any PHTHandleProtocol).self)

        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        connection?.invalidationHandler = {
          // If the connection gets invalidated then, on our operation queue thread, nil out our
          // reference to it.  This ensures that we attempt to rebuild it the next time around.
          self.lock.withLock {
            self.connection?.invalidationHandler = nil

            self.connection = nil
          }
        }
        connection?.resume()
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension AppServiceHandle: @unchecked Sendable {}

  @available(SwiftStdlib 5.3, *)
  extension AppServiceHandle: AppServiceHandleProtocol {

    public func codeSigningRequirement() async -> String {
      if #available(SwiftStdlib 5.7, *) {
        var codeSigningRequirementParts: [Substring] = []

        codeSigningRequirementParts.append("identifier \"com.tenbits.netbot\"")
        codeSigningRequirementParts.append("anchor apple generic")

        let propertyList =
          Bundle.main.object(forInfoDictionaryKey: "SMPrivilegedExecutables") as! [String: String]
        let team = propertyList.values.first.map {
          $0.split(separator: /\ and\ /)
            .filter { $0.starts(with: /^certificate leaf\[subject\./) }
            .first!
        }!
        codeSigningRequirementParts.append(team)

        return codeSigningRequirementParts.joined(separator: " and ")
      } else {
        // TODO: Fallback to SwiftStdlib 5.3
        return ""
      }
    }

    public func register(daemon plistName: String) async throws {
      if #available(macOS 13.0, *) {
        let daemon = SMAppService.daemon(plistName: plistName)
        try await register(plistName: plistName, service: daemon)
      }
    }

    public func register(agent plistName: String) async throws {
      if #available(macOS 13.0, *) {
        let agent = SMAppService.agent(plistName: plistName)
        try await register(plistName: plistName, service: agent)
      }
    }

    public func register(loginItem identifier: String) async throws {
      if #available(macOS 13.0, *) {
        let loginItem = SMAppService.loginItem(identifier: identifier)
        try await register(plistName: identifier, service: loginItem)
      }
    }

    public func unregister(daemon plistName: String) async throws {
      if #available(macOS 13.0, *) {
        let daemon = SMAppService.daemon(plistName: plistName)
        try await unregister(plistName: plistName, service: daemon)
      }
    }

    public func unregister(agent plistName: String) async throws {
      if #available(macOS 13.0, *) {
        let agent = SMAppService.agent(plistName: plistName)
        try await unregister(plistName: plistName, service: agent)
      }
    }

    public func unregister(loginItem identifier: String) async throws {
      if #available(macOS 13.0, *) {
        let loginItem = SMAppService.loginItem(identifier: identifier)
        try await unregister(plistName: identifier, service: loginItem)
      }
    }

    @available(macOS 13.0, *)
    public func status(daemon plistName: String) async -> SMAppService.Status {
      let daemon = SMAppService.daemon(plistName: plistName)
      return daemon.status
    }

    @available(macOS 13.0, *)
    public func status(agent plistName: String) async -> SMAppService.Status {
      let agent = SMAppService.agent(plistName: plistName)
      return agent.status
    }

    @available(macOS 13.0, *)
    public func status(loginItem identifier: String) async -> SMAppService.Status {
      let loginItem = SMAppService.loginItem(identifier: identifier)
      return loginItem.status
    }

    @available(macOS 13.0, *)
    public func openSystemSettingsLoginItems() async {
      SMAppService.openSystemSettingsLoginItems()
    }

    public func connect(matchService name: String) async throws -> NSXPCListenerEndpoint {
      connect0(matchService: name)

      // Call the helper tool to get the endpoint we need.
      let tool = try lock.withLock {
        try connection.remotePHTHandle()
      }
      let endpoint = await tool.listenerEndpoint()
      return endpoint
    }

    public func setupAuthorizationRights() async throws {
      guard authorizationRef != nil else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(errAuthorizationInvalidRef))
      }
    }

    public func authorizationExternalForm() async -> Data {
      lock.withLock {
        authorizationExternalForm
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension NSXPCConnection {

    /// Convert `remoteObjectProxy` to `any PHTHandleProtocol` if possible.
    ///
    /// Throw operationUnsupported if remote object proxy is not a `any PHTHandleProtocol` object, or
    /// error that `remoteObjectProxyWithErrorHandler` throws.
    func remotePHTHandle() throws -> any PHTHandleProtocol {
      try remoteObjectProxy(as: (any PHTHandleProtocol).self)
    }

    func remoteObjectProxy<Proxy: Sendable>(as type: Proxy.Type = Proxy.self) throws -> Proxy {
      var error: (any Error)?

      let remoteObjectProxy = remoteObjectProxyWithErrorHandler { error = $0 } as? Proxy

      guard error == nil else {
        throw error!
      }

      guard let remoteObjectProxy else {
        throw NEXPCServiceError.operationUnsupported
      }
      return remoteObjectProxy
    }
  }

  @available(SwiftStdlib 5.3, *)
  enum NEXPCServiceError: Error {
    case operationUnsupported
  }

  @available(SwiftStdlib 5.3, *)
  extension Data {
    var authorizationExternalForm: AuthorizationExternalForm {
      get throws {
        guard self.count == MemoryLayout<AuthorizationExternalForm>.size else {
          throw NSError(domain: NSOSStatusErrorDomain, code: Int(errAuthorizationInvalidRef))
        }
        return self.withUnsafeBytes {
          $0.load(as: AuthorizationExternalForm.self)
        }
      }
    }
  }
#endif
