//
// See LICENSE.txt for license information
//

import Anlzr
import CNELwIP
import Logging
import NEAddressProcessing
import NESOCKS
import NIOCore
import _DNSSupport

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

final class LwIPSOCKSProxy: PacketHandleProtocol, @unchecked Sendable {

  private let group: any EventLoopGroup
  private let eventLoop: any EventLoop

  private let listener: LwIPListener

  let device: UnsafeMutablePointer<netif>

  private let logger = Logger(label: "LwIP")

  public let packetFlow: any PacketTunnelFlow
  let dns: LocalDNSProxy

  init(group: any EventLoopGroup = .shared, packetFlow: any PacketTunnelFlow, dns: LocalDNSProxy) {
    let eventLoop = group.any()
    self.eventLoop = eventLoop

    self.group = group
    self.packetFlow = packetFlow
    self.dns = dns

    // Configure network interface in LwIP
    self.device = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.device.initialize(to: .init())
    self.listener = LwIPListener(eventLoop: eventLoop, group: eventLoop)
    self.listener.newConnectionHandler = newConnectionHandler
    self.initialize()
  }

  deinit {
    device.deinitialize(count: MemoryLayout<netif>.size)
    device.deallocate()
  }

  public func runIfActive() async throws {
    try await run()
  }

  public func run() async throws {
    listener.start(queue: .global())
  }

  public func shutdownGracefully() async {
    listener.cancel()
  }

  public func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    guard case .v4(let inhdr) = packetObject.headerFields else {
      return .discarded
    }
    guard case .tcp = inhdr.protocol else {
      return .discarded
    }

    let execute = {
      packetObject.data.withUnsafeReadableBytes {
        let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
        pbuf_take(p, $0.baseAddress, u16_t($0.count))
        self.device.pointee.input(p, self.device)
      }
    }
    if self.eventLoop.inEventLoop {
      execute()
    } else {
      self.eventLoop.execute(execute)
    }
    return .handled
  }

  private func initialize() {
    let execute = {
      lwip_init()

      var ipaddr = ip4_addr(addr: ipaddr_addr("198.18.0.1"))
      var netmask = ip4_addr(addr: ipaddr_addr("255.254.0.0"))
      var gw = ip4_addr(addr: ipaddr_addr("198.18.0.1"))

      netif_add(
        self.device, &ipaddr, &netmask, &gw, Unmanaged.passUnretained(self).toOpaque(),
        { contextPtr in
          guard let contextPtr = contextPtr else { return ERR_IF }
          contextPtr.pointee.mtu = 1500
          contextPtr.pointee.output = { contextPtr, bufferPtr, addressPtr in
            guard let opaquePtr = contextPtr?.pointee.state else {
              return ERR_IF
            }
            guard let data = bufferPtr else {
              return ERR_OK
            }

            let stack = Unmanaged<LwIPSOCKSProxy>.fromOpaque(opaquePtr).takeUnretainedValue()

            var byteBuffer = ByteBuffer()
            byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len))
            {
              Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.tot_len, 0))
            }
            guard let packetObject = NEPacket(data: byteBuffer, protocolFamily: .inet) else {
              return ERR_BUF
            }
            stack.packetFlow.writePacketObjects([packetObject])
            return ERR_OK
          }
          //      contextPtr.pointee.output_ip6 = { contextPtr, bufferPtr, addressPtr in
          //        guard let pointee = addressPtr?.pointee else { return ERR_OK }
          //        let address = ip_addr_t(
          //          u_addr: .init(ip6: pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
          //        c_ne_lwip_write_bridge(contextPtr, bufferPtr, address)
          //        return ERR_OK
          //      }
          return ERR_OK
        }, ip_input)
      netif_set_default(self.device)
      netif_set_up(self.device)
    }

    if self.eventLoop.inEventLoop {
      execute()
    } else {
      self.eventLoop.execute(execute)
    }
  }

  private func newConnectionHandler(_ connection: LwIPConnection) {
    connection.start(queue: .global())
    guard var destinationAddress = connection.localAddress else {
      connection.close()
      return
    }

    Task {
      // Reverse reserved IPs to domain name if needed.
      if case .hostPort(host: let host, port: let port) = destinationAddress {
        if case .ipv4(let address) = host, dns.availableIPPool.contains(address) {
          // According to our dns proxy settings that every reserved IPs should
          // be able to query PTR records.
          //
          // Consider as invalid connection if we can't query valid PTR records,
          // and close the connection.
          let prefix = "\(address)".split(separator: ".").reversed().joined(separator: ".")
          let name = try? await self.dns.queryPTR(name: "\(prefix).in-addr.arpa").first?.data
          guard let name else {
            connection.close()
            return
          }

          // Update destination address to use original domain name and port.
          destinationAddress = .hostPort(host: .name(name), port: port)
        }
      }

      do {
        let channel = try await ClientBootstrap(group: .shared)
          .channelOption(.allowRemoteHalfClosure, value: true)
          .channelInitializer { channel in
            channel.eventLoop.makeFutureWithTask {
              try await channel.configureSOCKS5Pipeline(destinationAddress: destinationAddress) {
                channel.pipeline.addHandler(ResponseHandler(connection: connection)).map { channel }
              }.get()
            }
          }
          .connect(to: .init(ipAddress: "127.0.0.1", port: 6153))
          .get()

        @Sendable func read() {
          // After connection started the state should be changed to .ready if no error accord.
          guard case .ready = connection.state else {
            return
          }

          connection.receive(maximumLength: 8192) { content, contentContext, isComplete, error in
            // If current read contains valid data then write to connected SOCKS5 server.
            if let content {
              Task {
                self.logger.trace("\(String(buffer: content))")
                try await channel.writeAndFlush(content)
              }
            }

            guard contentContext !== LwIPConnection.ContentContext.finalMessage else {
              // EOF
              Task {
                try await channel.close(mode: .output)
              }
              return
            }

            // If current read contains data then perform a new read immediately.
            // otherwise wait for a short time then read.
            if let content, !content.isEmpty {
              read()
            } else {
              Task {
                try await Task.sleep(for: .seconds(0.1))
                read()
              }
            }
          }
        }

        read()

        try await channel.closeFuture.get()
        logger.trace("SOCKS5 connection closed")
      } catch {
        logger.error("\(error)")
        connection.close()
      }
    }
  }
}

final class ResponseHandler: ChannelInboundHandler, Sendable {
  typealias InboundIn = ByteBuffer

  private let logger = Logger(label: "lwip-response")
  let connection: LwIPConnection
  init(connection: LwIPConnection) {
    self.connection = connection
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let buffer = unwrapInboundIn(data)
    logger.trace("\(String(buffer: buffer))")
    connection.send(content: buffer, contentContext: .defaultStream, isComplete: true) { error in
      if let error {
        self.logger.error("\(error)")
      }
    }
    context.fireChannelRead(data)
  }
}
