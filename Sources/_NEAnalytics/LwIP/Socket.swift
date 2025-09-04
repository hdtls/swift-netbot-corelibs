//
// See LICENSE.txt for license information
//

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
