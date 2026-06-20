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

/// Information about a process and its associated activity.
///
/// ``ProcessReport`` associates a process identifier with the connection
/// and application information observed for that process.
///
/// Use this type to correlate network activity with the process and
/// application that generated it.
///
/// Use ``ProcessReport`` when working with responses in memory.
/// Use ``V1/ProcessReport`` when storing response data.
///
/// - SeeAlso: ``V1/ProcessReport``
@available(SwiftStdlib 6.0, *)
public struct ProcessReport: Codable, Hashable, Sendable {

  /// The identifier of the process.
  ///
  /// This value corresponds to the operating system process identifier (PID)
  /// of the observed process.
  public var processIdentifier: Int32?

  /// The application associated with the process.
  ///
  /// This value identifies the application to which the process belongs
  /// and provides additional application metadata.
  public var program: Program?

  package init(processIdentifier: Int32?, program: Program?) {
    self.processIdentifier = processIdentifier
    self.program = program
  }

  package init() {}
}

@available(SwiftStdlib 6.0, *)
extension ProcessReport {

  /// In used persistent model typealias.
  public typealias Model = V1.ProcessReport

  /// Create a new ``ProcessReport`` from persistent process report.
  /// - Parameter persistentModel: Persistent process report.
  public init(persistentModel: Model) {
    processIdentifier = persistentModel.processIdentifier
  }
}
