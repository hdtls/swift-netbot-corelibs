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
  import NEAddressProcessing
  import NetbotLiteData
  import NetbotXPC
  import Synchronization

  @available(SwiftStdlib 6.0, *)
  final public class ProcessInspector: ProcessResolver {

    private let table: Mutex<[Address: Address]> = Mutex([:])

    private let assistantd: any _ProcessResolver

    public convenience init() {
      self.init(backing: PHTSession.shared)
    }

    init(backing: some _ProcessResolver) {
      assistantd = backing
    }

    func store(_ address: Address, to newAddress: Address) {
      self.table.withLock {
        $0[address] = newAddress
      }
    }

    public func processInfo(connection: Connection) async throws -> ProcessReport {
      let port = try self.table.withLock {
        guard var sourceEndpoint = connection.establishmentReport?.sourceEndpoint else {
          throw AnalyzeError.operationUnsupported
        }

        if let endpoint = $0[sourceEndpoint] {
          sourceEndpoint = endpoint
          connection.withMutation(keyPath: \.establishmentReport) {
            connection.$establishmentReport.withLock {
              $0?.sourceEndpoint = sourceEndpoint
            }
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

  @available(SwiftStdlib 6.0, *)
  protocol _ProcessResolver: Sendable {

    /// Request process info with socket port.
    func processInfo(address: UInt16) async throws -> ProcessInfo?
  }
#endif

#if os(macOS)
  @available(SwiftStdlib 6.0, *)
  extension PHTSession: _ProcessResolver {}

  @available(SwiftStdlib 6.0, *)
  typealias ProcessInfo = NetbotXPC.ProcessInfo
#else
  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  @available(SwiftStdlib 6.0, *)
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
