//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore

@available(SwiftStdlib 5.3, *)
class ServerSocket: BaseSocket {

  convenience init() {
    self.init(socket: tcp_new())
  }

  func listen(backlog: UInt8 = 128) throws {
    self.descriptor = tcp_listen_with_backlog(descriptor, backlog)
  }
}
