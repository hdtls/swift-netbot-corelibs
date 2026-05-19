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

import NEAddressProcessing
import NetbotLite
import NetbotLiteData
import SynchronizationExtras

#if os(macOS)
  import NetbotXPC
#endif

#if !canImport(Darwin) || !NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class ProcessResolver: ProcessReporting {

  @LockableTracked(accessors: .get)
  private var table: [Address: Address] = [:]

  private let assistantd: any _ProcessInspector

  static let shared = ProcessResolver()

  private convenience init() {
    #if os(macOS)
      self.init(backing: PrivilegeScope.shared)
    #else
      self.init(backing: OperationUnsupportedProcessInspector())
    #endif
  }

  init(backing: some _ProcessInspector) {
    assistantd = backing
  }

  func store(_ address: Address, to newAddress: Address) {
    self.$table.withLock {
      $0[address] = newAddress
    }
  }

  func processInfo(connection: Connection) async throws -> ProcessReport {
    let port = try self.$table.withLock {
      guard var sourceEndpoint = connection.establishmentReport?.sourceEndpoint else {
        throw AnalyzeError.operationUnsupported
      }

      if let endpoint = $0[sourceEndpoint] {
        sourceEndpoint = endpoint
        connection.$establishmentReport.withLock {
          $0?.sourceEndpoint = sourceEndpoint
        }
      }

      guard let port = sourceEndpoint.port, port <= Int(UInt16.max), port >= 0 else {
        throw AnalyzeError.operationUnsupported
      }
      return port
    }

    let processInfo = try await assistantd.processInfo(address: UInt16(port))
    return ProcessReport(
      processIdentifier: processInfo?.processIdentifier,
      program: Program(
        localizedName: processInfo?.processName ?? "Unknown",
        bundleURL: processInfo?.processBundleURL,
        executableURL: processInfo?.processExecutableURL,
        iconTIFFRepresentation: processInfo?.processIconTIFFRepresentation
      )
    )
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
protocol _ProcessInspector: Sendable {

  /// Request process info with socket port.
  #if os(macOS)
    func processInfo(address: UInt16) async throws -> NetbotXPC.ProcessInfo?
  #else
    func processInfo(address: UInt16) async throws -> ProcessInfo?
  #endif
}

#if os(macOS)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension PrivilegeScope: _ProcessInspector {}

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  typealias ProcessInfo = NetbotXPC.ProcessInfo
#else
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  struct ProcessInfo: Hashable, Codable, Sendable {
    /// Indicates the name of the application.
    /// This is dependent on the current localization of the referenced app, and is suitable for presentation to the user.
    var processName: String?

    /// Indicates the URL to the application's bundle, or nil if the application does not have a bundle.
    var processBundleURL: URL?

    /// Indicates the URL to the application's executable.
    var processExecutableURL: URL?

    /// Indicates the process identifier (pid) of the application.
    var processIdentifier: Int32?

    /// Indicates the icon TIFF representation data of the application.
    var processIconTIFFRepresentation: Data?
  }
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct OperationUnsupportedProcessInspector: _ProcessInspector {
  func processInfo(address: UInt16) async throws -> ProcessInfo? {
    throw AnalyzeError.operationUnsupported
  }
}
