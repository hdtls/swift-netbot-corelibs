//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import Observation

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    import SwiftData
  #endif

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      @Model
    #else
      @Observable
    #endif
    final public class _ProcessReport {

      /// Indicates the process identifier (pid) of the application.
      public var processIdentifier: Int32?

      public var connection: _Connection?

      public var program: _Program?

      public init() {}
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._ProcessReport {

    /// Merge new values from data transfer object.
    /// - Parameter data: New `ProcessReport` to merge.
    public func mergeValues(_ data: ProcessReport) {
      #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
        processIdentifier = data.processIdentifier
      #else
        if processIdentifier != data.processIdentifier {
          processIdentifier = data.processIdentifier
        }
      #endif
    }
  }
#endif
