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
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ForwardProtocolRejectTinyGIF: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "REJECT-TINYGIF") {
    self.name = name
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolRejectTinyGIF: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    throw AnalyzeError.connectionRefused
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolRejectTinyGIF: ForwardProtocolConvertible {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocol where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardProtocolConvertible where Self == ForwardProtocolRejectTinyGIF {

  /// Return the default `ForwardProtocolRejectTinyGIF`.
  public static var rejectTinyGIF: ForwardProtocolRejectTinyGIF {
    ForwardProtocolRejectTinyGIF()
  }
}
