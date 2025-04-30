//
// See LICENSE.txt for license information
//

import Logging
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

#if swift(>=6.0)
  import CNELwIP
#else
  @_implementationOnly import CNELwIP
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

struct LwIPError: Error {
  let code: err_t

  var description: String {
    switch code {
    case ERR_OK: return "Ok."
    case ERR_MEM: return "Out of memory error."
    case ERR_BUF: return "Buffer error."
    case ERR_TIMEOUT: return "Timeout."
    case ERR_RTE: return "Routing problem."
    case ERR_INPROGRESS: return "Operation in progress."
    case ERR_VAL: return "Illegal value."
    case ERR_WOULDBLOCK: return "Operation would block."
    case ERR_USE: return "Address in use."
    case ERR_ALREADY: return "Already connecting."
    case ERR_ISCONN: return "Already connected."
    case ERR_CONN: return "Not connected."
    case ERR_IF: return "Low-level netif error."
    case ERR_ABRT: return "Connection aborted."
    case ERR_RST: return "Connection reset."
    case ERR_CLSD: return "Connection closed."
    case ERR_ARG: return "Illegal argument."
    default: return ""
    }
  }
}

public protocol LwIPStackDelegate: AnyObject {
  func stack(_ stack: LwIPStack, didReceive channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>)
    async throws

  func stack(_ stack: LwIPStack, didReceive response: [ByteBuffer])
}

final public class LwIPStack: @unchecked Sendable {

  private let logger = Logger(label: "LwIP")
  private var channel: NIOAsyncChannel<NIOAsyncChannel<ByteBuffer, ByteBuffer>, Never>!

  public weak var delegate: (any LwIPStackDelegate)? = .none

  let device: UnsafeMutablePointer<netif>?
  let eventLoop: any EventLoop

  public init(eventLoop: any EventLoop) {
    self.eventLoop = eventLoop

    // Configure network interface in LwIP
    self.device = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.device?.initialize(to: .init())

    if eventLoop.inEventLoop {
      c_ne_lwip_initialize(self)
    } else {
      _ = eventLoop.submit {
        c_ne_lwip_initialize(self)
      }
    }

//    let timerInterval = TimeAmount.milliseconds(Int64(TCP_TMR_INTERVAL))
//    eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: timerInterval) { _ in
//      sys_check_timeouts()
//    }
  }

  public convenience init() {
    #if canImport(Network)
      let eventLoop = NIOTSEventLoopGroup.singleton.next()
    #else
      let eventLoop = MultiThreadedEventLoopGroup.singleton.next()
    #endif
    self.init(eventLoop: eventLoop)
  }

  deinit {
    guard let device else { return }
    device.deinitialize(count: MemoryLayout<netif>.size)
    device.deallocate()
  }

  public func runIfActive() async throws {
    channel = try await ServerBootstrap(group: self.eventLoop)
      .bind(to: .hostPort(host: "0.0.0.0", port: .any)) { childChannel in
        childChannel.eventLoop.makeCompletedFuture {
          try NIOAsyncChannel<ByteBuffer, ByteBuffer>(wrappingChannelSynchronously: childChannel)
        }
      }

    Task.detached(priority: .background) {
      do {
        try await withThrowingDiscardingTaskGroup { g in
          try await self.channel.executeThenClose { inbound in
            for try await channel in inbound {
              g.addTask {
                try await self.delegate?.stack(self, didReceive: channel)
              }
            }
          }
        }
      } catch {
        self.logger.error("\(error)")
      }
    }
  }

  public func write(_ packetData: ByteBuffer) async throws {
    if eventLoop.inEventLoop {
      packetData.withUnsafeReadableBytes {
        let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
        pbuf_take(p, $0.baseAddress, u16_t($0.count))
        ip_input(p, self.device)
      }
    } else {
      try await eventLoop.submit {
        packetData.withUnsafeReadableBytes {
          let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
          pbuf_take(p, $0.baseAddress, u16_t($0.count))
          ip_input(p, self.device)
        }
      }
      .get()
    }
  }
}
