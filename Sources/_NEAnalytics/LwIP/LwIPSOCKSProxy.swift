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
    let address = try SocketAddress(ipAddress: "0.0.0.0", port: 0)
    try await listener.register()
    try await listener.bind(to: address)
  }

  public func shutdownGracefully() async {
    listener.close(promise: nil)
  }

  public func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    guard case .v4(let inhdr) = packetObject.headerFields else {
      return .discarded
    }
    guard case .tcp = inhdr.protocol else {
      return .discarded
    }

    let execute: @Sendable () -> Void = {
      packetObject.data.withUnsafeReadableBytes {
        let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
        pbuf_take(p, $0.baseAddress, u16_t($0.count))
        if self.device.pointee.input(p, self.device) != ERR_OK {
          pbuf_free(p)
        }
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
    let execute: @Sendable () -> Void = {
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
            _ = stack.packetFlow.writePacketObjects([packetObject])
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
    Task {
      try await withThrowingTaskGroup(of: Void.self) { g in
        g.addTask {
          try await connection.closeFuture.get()
          self.logger.trace("LwIP connection closed")
        }
        g.addTask {
          guard let destination = connection.localAddress, let host = destination.ipAddress,
            let port = destination.port
          else {
            connection.close(promise: nil)
            return
          }

          var destinationAddress: Address = .hostPort(
            host: .init(host),
            port: .init(rawValue: UInt16(port))
          )

          // Reverse reserved IPs to domain name if needed.
          if case .hostPort(let host, let port) = destinationAddress {
            if case .ipv4(let address) = host, self.dns.availableIPPool.contains(address) {
              // According to our dns proxy settings that every reserved IPs should
              // be able to query PTR records.
              //
              // Consider as invalid connection if we can't query valid PTR records,
              // and close the connection.
              let prefix = "\(address)".split(separator: ".").reversed().joined(separator: ".")
              let name = try? await self.dns.queryPTR(name: "\(prefix).in-addr.arpa").first?.data
              guard let name else {
                connection.close(promise: nil)
                return
              }

              // Update destination address to use original domain name and port.
              destinationAddress = .hostPort(host: .name(name), port: port)
            }
          }

          do {
            let destinationAddress = destinationAddress
            let channel = try await ClientBootstrap(group: .shared)
              .channelOption(.allowRemoteHalfClosure, value: true)
              .connect(to: .init(ipAddress: "127.0.0.1", port: 6153)) { channel in
                channel.configureSOCKS5Pipeline(destinationAddress: destinationAddress) {
                  channel.pipeline.addHandler(ResponseHandler(connection: connection)).map {
                    channel
                  }
                }
              }
              .get()

            @Sendable func read() {
              connection.receive(maximumLength: 8192) {
                content, contentContext, isComplete, error in
                // If current read contains valid data then write to connected SOCKS5 server.
                if let content {
                  Task {
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
            self.logger.trace("LwIP SOCKS5 connection closed")
            connection.close(mode: .output, promise: nil)
          } catch {
            self.logger.error("\(error)")
            connection.close(promise: nil)
          }
        }
        try await g.waitForAll()
      }
    }
  }
}

final private class ResponseHandler: ChannelInboundHandler, Sendable {
  typealias InboundIn = ByteBuffer

  private let connection: LwIPConnection

  init(connection: LwIPConnection) {
    self.connection = connection
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let buffer = unwrapInboundIn(data)
    connection.writeAndFlush(buffer, promise: nil)
    context.fireChannelRead(data)
  }
}
