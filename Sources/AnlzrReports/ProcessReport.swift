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

@available(SwiftStdlib 5.3, *)
public struct ProcessReport: Codable, Hashable, Sendable {

  /// Indicates the process identifier (pid) of the application.
  public var processIdentifier: Int32?

  public var program: Program?

  public init(processIdentifier: Int32? = nil, program: Program? = nil) {
    self.processIdentifier = processIdentifier
    self.program = program
  }
}

#if swift(>=6.3) || canImport(Darwin)
  @available(SwiftStdlib 5.9, *)
  extension ProcessReport {

    public typealias PersistentModel = V1._ProcessReport

    public init(persistentModel: PersistentModel) {
      processIdentifier = persistentModel.processIdentifier
    }
  }
#endif
