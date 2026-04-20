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

import CNELwIP
import NIOCore

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
class ServerSocket: BaseSocket {

  convenience init() {
    self.init(socket: tcp_new())
  }

  func listen(backlog: UInt8 = 128) throws {
    self.descriptor = tcp_listen_with_backlog(descriptor, backlog)
  }
}
