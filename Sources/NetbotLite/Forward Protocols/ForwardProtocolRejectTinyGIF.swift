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

import Logging
import NIOCore
import NetbotLiteData

/// `ForwardProtocolRejectTinyGIF` will reject connection and response a tiny gif.
@available(SwiftStdlib 6.0, *)
public struct ForwardProtocolRejectTinyGIF: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT-TINYGIF") {
    self.name = name
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolRejectTinyGIF: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnalyzeError.connectionRefused
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolRejectTinyGIF: ForwardProtocolConvertible {}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocol where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardProtocolConvertible where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}
