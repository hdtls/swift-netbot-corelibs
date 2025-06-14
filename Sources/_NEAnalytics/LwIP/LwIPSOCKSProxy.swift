//
// See LICENSE.txt for license information
//

import Anlzr
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

  private let core: LwIP

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
    self.core = LwIP(
      packetFlow: packetFlow,
      address: IPv4Address("198.18.0.1")!,
      netmask: IPv4Address("255.254.0.0")!,
      gateway: IPv4Address("198.18.0.1")!
    )
    self.listener = LwIPListener(eventLoop: eventLoop, group: eventLoop)
    self.listener.newConnectionHandler = newConnectionHandler
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

    if self.eventLoop.inEventLoop {
      try self.core.handleInput(packetObject)
    } else {
      try await self.eventLoop.submit {
        try self.core.handleInput(packetObject)
      }.get()
    }
    return .handled
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
              connection.receive(maximumLength: 8192) { content, contentContext, _, error in
                guard error == nil else {
                  channel.close(promise: nil)
                  return
                }

                Task {
                  // If current read contains valid data then write to connected SOCKS5 server.
                  if let content {
                    try await channel.writeAndFlush(content)
                  }

                  if contentContext === LwIPConnection.ContentContext.finalMessage {
                    // EOF
                    try await channel.close(mode: .output)
                    return
                  }

                  try await Task.sleep(for: .seconds(0.1))
                  read()
                }
              }
            }

            read()

            try await channel.closeFuture.get()
            self.logger.trace("LwIP SOCKS5 connection closed")
            connection.close(promise: nil)
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
