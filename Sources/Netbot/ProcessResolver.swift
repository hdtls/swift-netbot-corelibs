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

import NEAddressProcessing
import NIOConcurrencyHelpers
import NetbotLite
import NetbotLiteData

#if os(macOS)
  import NetbotDaemons
#endif

@available(SwiftStdlib 5.3, *)
final class ProcessResolver: ProcessReporting {

  @LockableTracked(accessors: .get)
  private var table: [Address: Address]

  #if os(macOS)
    private let privileged = PrivilegeScope.shared
  #endif

  static let shared = ProcessResolver()

  init() {
    _table = .init([:])
  }

  func store(_ address: Address, to newAddress: Address) {
    self._table.withLock {
      $0[address] = newAddress
    }
  }

  func processInfo(connection: Connection) async throws -> ProcessReport {
    do {
      let port = try self._table.withLock {
        guard var sourceEndpoint = connection.establishmentReport?.sourceEndpoint else {
          throw AnalyzeError.operationUnsupported
        }

        if let endpoint = $0[sourceEndpoint] {
          sourceEndpoint = endpoint
          connection._establishmentReport.withLock {
            $0?.sourceEndpoint = sourceEndpoint
          }
        }

        guard let port = sourceEndpoint.port, port <= Int(UInt16.max), port >= 0 else {
          throw AnalyzeError.operationUnsupported
        }
        return port
      }

      #if os(macOS)
        let processInfo = try await privileged.processInfo(address: UInt16(port))
        return ProcessReport(
          processIdentifier: processInfo?.processIdentifier,
          program: Program(
            localizedName: processInfo?.processName ?? "Unknown",
            bundleURL: processInfo?.processBundleURL,
            executableURL: processInfo?.processExecutableURL,
            iconTIFFRepresentation: processInfo?.processIconTIFFRepresentation
          )
        )
      #else
        return ProcessReport()
      #endif
    } catch {
      return ProcessReport()
    }
  }
}
