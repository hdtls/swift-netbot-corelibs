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

import CNELwIP
import NIOCore

@available(SwiftStdlib 5.3, *)
class Socket: BaseSocket {

  func write(pointer: UnsafeRawBufferPointer, flags: Int32) throws {
    var rt = tcp_write(self.descriptor, pointer.baseAddress, u16_t(pointer.count), UInt8(flags))
    guard rt == ERR_OK else {
      throw IOError(errnoCode: err_to_errno(rt), reason: "tcp_write")
    }

    rt = tcp_output(self.descriptor)
    guard rt == ERR_OK else {
      throw IOError(errnoCode: err_to_errno(rt), reason: "tcp_output")
    }
  }
}
