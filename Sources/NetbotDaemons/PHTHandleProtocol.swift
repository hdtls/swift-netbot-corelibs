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
  import _PrivilegeSupport

  /// PHTHandleProtocol is the NSXPCConnection-based protocol implemented by the helper tool
  /// and called by the app.
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

    /// Returns the process info with address.
    ///
    /// - Parameter address: Socket address the process running on.
    /// - Returns: Any mached process else return nil.
    func processInfo(address: UInt16) async throws -> _PrivilegeSupport.ProcessInfo?
  }
#endif
