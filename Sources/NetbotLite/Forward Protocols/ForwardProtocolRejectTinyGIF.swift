// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Logging
import NIOCore
import NetbotLiteData

/// `ForwardProtocolRejectTinyGIF` will reject connection and response a tiny gif.
@available(SwiftStdlib 5.3, *)
public struct ForwardProtocolRejectTinyGIF: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT-TINYGIF") {
    self.name = name
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolRejectTinyGIF: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnalyzeError.connectionRefused
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolRejectTinyGIF: ForwardProtocolConvertible {}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocol where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolConvertible where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}
