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

#if SWTNE_REQUIRES_LWIP
  import CNELwIP
  import NIOCore

  @available(SwiftStdlib 6.0, *)
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
#endif
