//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore

class ServerSocket: BaseSocket {

  convenience init() {
    self.init(socket: tcp_new())
  }

  func listen(backlog: UInt8 = 128) throws {
    guard self.descriptor.pointee.state == CLOSED || self.isOpen else {
      throw IOError(errnoCode: EBADF, reason: "file descriptor already closed!")
    }
    self.descriptor = tcp_listen_with_backlog(descriptor, backlog)
  }
}
