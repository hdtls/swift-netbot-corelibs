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
  import os

  /// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the
  /// service to make it available to the process hosting the service over an NSXPCConnection.
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final public class AppServiceHandle {

    private let authorizationExternalForm: Data

    /// only accessed or modified by operations on self.queue
    private var connection: NSXPCConnection!
    private let lock = NSLock()

    private var authorizationRef: AuthorizationRef?

    private let logger = Logger(
      subsystem: ServiceName.assistantService.rawValue,
      category: "AssistantService"
    )

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

    private func register(plistName: String, service: SMAppService) async throws {
      do {
        try service.register()
        logger
          .debug("Launch service \(plistName, privacy: .public) has been successfully registered")
      } catch {
        logger.error("Launch service \(plistName, privacy: .public) register failed \(error)")
      }
    }

    private func unregister(plistName: String, service: SMAppService) async throws {
      do {
        try await SMAppService.daemon(plistName: plistName).unregister()
        logger
          .debug("Launch service \(plistName, privacy: .public) has been successfully unregistered")
      } catch {
        logger.error("Launch service \(plistName, privacy: .public) unregister failed \(error)")
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension AppServiceHandle: @unchecked Sendable {}

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension AppServiceHandle: AppServiceHandleProtocol {

    public func codeSigningRequirement() async -> String {
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
    }

    public func register(daemon plistName: String) async throws {
      let daemon = SMAppService.daemon(plistName: plistName)
      try await register(plistName: plistName, service: daemon)
    }

    public func unregister(daemon plistName: String) async throws {
      let daemon = SMAppService.daemon(plistName: plistName)
      try await unregister(plistName: plistName, service: daemon)
    }

    public func status(daemon plistName: String) async -> SMAppService.Status {
      let daemon = SMAppService.daemon(plistName: plistName)
      return daemon.status
    }

    public func openSystemSettingsLoginItems() async {
      SMAppService.openSystemSettingsLoginItems()
    }

    public func connect(matchService name: String) async throws -> NSXPCListenerEndpoint {
      connect0(matchService: name)

      // Call the helper tool to get the endpoint we need.
      let tool = try lock.withLock {
        try connection.assistantd()
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension NSXPCConnection {

    /// Convert `remoteObjectProxy` to `any PHTHandleProtocol` if possible.
    ///
    /// Throw operationUnsupported if remote object proxy is not a `any PHTHandleProtocol` object, or
    /// error that `remoteObjectProxyWithErrorHandler` throws.
    func assistantd() throws -> any PHTHandleProtocol {
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  enum NEXPCServiceError: Error {
    case operationUnsupported
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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
