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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
  #endif
  final public class _ProcessReport {

    /// Indicates the process identifier (pid) of the application.
    public var processIdentifier: Int32?

    public var connection: _Connection?

    public var program: _Program?

    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1._ProcessReport {

  /// Merge new values from DTO.
  /// - Parameter data: New `ProcessReport` to merge.
  public func mergeValues(_ data: ProcessReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      processIdentifier = data.processIdentifier
    #else
      if processIdentifier != data.processIdentifier {
        processIdentifier = data.processIdentifier
      }
    #endif
  }
}
