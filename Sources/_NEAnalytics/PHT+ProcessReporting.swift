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
  import Anlzr
  import AnlzrReports
  import NEAddressProcessing
  import _PrivilegeSupport

  @available(SwiftStdlib 5.3, *)
  extension PrivilegeScope: ProcessReporting {

    public func processInfo(address: Address) async throws -> ProcessReport {
      guard let port = address.port, port <= Int(UInt16.max), port >= 0 else {
        throw AnlzrError.operationUnsupported
      }
      let processInfo = try await processInfo(address: UInt16(port))
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
#endif
