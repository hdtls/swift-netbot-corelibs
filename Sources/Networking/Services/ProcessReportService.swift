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

import AnlzrReports
import NEAddressProcessing

/// Protocol for process report generator
@available(SwiftStdlib 5.3, *)
public protocol ProcessReporting: Service, Sendable {

  /// Request process info with socket address.
  ///
  /// - Parameter connection: Connection the requested process runs on.
  /// - Returns: Generated process report.
  func processInfo(connection: Connection) async throws -> ProcessReport
}

/// A default `ProcessReporting` object.
///
/// Return an empty report entity for process info report request by default.
@available(SwiftStdlib 5.3, *)
struct DefaultProcessReporting: ProcessReporting {

  func processInfo(connection: Connection) async throws -> ProcessReport {
    return .init()
  }
}

@available(SwiftStdlib 5.3, *)
extension Analyzer.Services {

  public var processReport: ServiceProvider<any ProcessReporting> {
    .init(application: self.application)
  }
}
