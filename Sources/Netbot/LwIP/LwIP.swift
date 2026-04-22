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
import Logging
import NEAddressProcessing
import NESOCKS
import NIOCore
import NetbotLite
import _DNSSupport

#if canImport(Darwin) && NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@Lockable final class LwIP: @unchecked Sendable {

  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func inet_aton(_ cp: String, _ address: UnsafeMutablePointer<ip_addr_t>) throws {
    try cp.withCString {
      if ipaddr_aton($0, address) != 1 {
        throw IOError(errnoCode: EINVAL, reason: #function)
      }
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func inet_ntoa(_ address: ip_addr_t?) throws -> String {
    guard let address else {
      throw IOError(errnoCode: EINVAL, reason: #function)
    }
    return withUnsafePointer(to: address) {
      String(cString: ipaddr_ntoa($0))
    }
  }

  private let group: any EventLoopGroup
  private let eventLoop: any EventLoop
  private let listener: LwIPListener
  private let logger = Logger(label: "LwIP")
  private let packetFlow: any PacketTunnelFlow
  private let dns: LocalDNSProxy
  private let device: UnsafeMutablePointer<netif>

  private var packetsReadLoop: Task<Void, any Error>?

  init(group: any EventLoopGroup = .shared, packetFlow: any PacketTunnelFlow, dns: LocalDNSProxy) {
    let eventLoop = group.any()
    self.eventLoop = eventLoop
    self.group = group
    self.packetFlow = packetFlow
    self.dns = dns
    self.listener = LwIPListener(eventLoop: eventLoop, group: group)
    self._packetsReadLoop = .init(nil)
    self.device = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.device.initialize(to: .init())

    lwip_init()

    // Configure network interface in custom IP stack.
    var _ipaddr = ip_addr_any
    try! LwIP.inet_aton("198.18.0.1", &_ipaddr)

    var _netmask = ip_addr_any
    try! LwIP.inet_aton("255.254.0.0", &_netmask)

    var _gateway = ip_addr_any
    try! LwIP.inet_aton("198.18.0.1", &_gateway)

    netif_add(
      self.device, &_ipaddr.u_addr.ip4, &_netmask.u_addr.ip4, &_gateway.u_addr.ip4,
      Unmanaged.passUnretained(self).toOpaque(),
      { contextPtr in
        guard let contextPtr = contextPtr else { return ERR_IF }
        contextPtr.pointee.mtu = 1500
        contextPtr.pointee.output = { contextPtr, bufferPtr, _ in
          guard let data = bufferPtr else {
            return ERR_OK
          }

          guard let opaquePtr = contextPtr?.pointee.state else {
            pbuf_free(data)
            return ERR_IF
          }

          let device = Unmanaged<LwIP>.fromOpaque(opaquePtr).takeUnretainedValue()

          var byteBuffer = ByteBuffer()
          byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len)) {
            Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.tot_len, 0))
          }

          guard let packetObject = NEPacket(data: byteBuffer, protocolFamily: .inet) else {
            pbuf_free(data)
            return ERR_BUF
          }
          _ = device.packetFlow.writePacketObjects([packetObject])
          return ERR_OK
        }
        return ERR_OK
      },
      ip_input
    )

    netif_set_default(self.device)

    self.listener.newConnectionHandler = newConnectionHandler
  }

  deinit {
    netif_remove(self.device)
    self.device.deinitialize(count: MemoryLayout<netif>.size)
    self.device.deallocate()
  }

  func run() async throws {
    let address = try SocketAddress(ipAddress: "0.0.0.0", port: 0)

    try await eventLoop.submit { netif_set_up(self.device) }.get()

    try await listener.register()
    try await listener.bind(to: address)

    dns.packetFlow = packetFlow
    packetsReadLoop = Task { [weak self] in
      guard let self else { return }
      try await readPacketsIfActive()
    }
  }

  func shutdownGracefully() async throws {
    listener.close(promise: nil)

    try await eventLoop.submit { netif_set_down(self.device) }.get()

    packetsReadLoop?.cancel()
    packetsReadLoop = nil
    dns.packetFlow = nil
  }

  private func readPacketsIfActive() async throws {
    try Task.checkCancellation()

    for packetObject in await packetFlow.readPacketObjects() {
      try await handleInput(packetObject)
    }

    try await readPacketsIfActive()
  }

  @discardableResult
  private func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    guard case .v4(let inhdr) = packetObject.headerFields else {
      return .discarded
    }

    guard inhdr.destinationAddress != self.dns.bindAddress else {
      try await self.dns.handleInput(packetObject)
      return .handled
    }

    guard case .tcp = inhdr.protocol else {
      return .discarded
    }

    @inline(__always) func input(_ packetObject: NEPacket) throws {
      try packetObject.data.withUnsafeReadableBytes {
        let p = pbuf_alloc(PBUF_RAW, UInt16($0.count), PBUF_RAM)
        pbuf_take(p, $0.baseAddress, UInt16($0.count))
        let errno = err_to_errno(self.device.pointee.input(p, self.device))
        guard errno != 0 else {
          return
        }
        pbuf_free(p)
        throw IOError(errnoCode: errno, reason: #function)
      }
    }

    if self.eventLoop.inEventLoop {
      try input(packetObject)
    } else {
      try await self.eventLoop.submit {
        try input(packetObject)
      }.get()
    }
    return .handled
  }

  private func newConnectionHandler(_ connection: LwIPConnection) {
    Task {
      try await withThrowingTaskGroup(of: Void.self) { g in
        g.addTask { [weak self] in
          guard let self else { return }
          try await connection.closeFuture.get()
          self.logger.trace("LwIP connection closed")
        }
        g.addTask { [weak self] in
          guard let self else { return }
          guard let source = connection.remoteAddress,
            let destination = connection.localAddress, let host = destination.ipAddress,
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
              .connect(to: .init(ipAddress: "127.0.0.1", port: 6153))
              .get()

            guard let localAddress = channel.localAddress else {
              throw ChannelError.unknownLocalAddress
            }

            try? ProcessResolver.shared.store(
              localAddress.asAddress(),
              to: .hostPort(host: "127.0.0.1", port: .init(rawValue: UInt16(source.port ?? 0)))
            )

            try await channel.configureSOCKSConnectionPipeline(
              destinationAddress: destinationAddress
            ) {
              channel.pipeline.addHandler(ResponseHandler(connection: connection))
            }
            .get()
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

                  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
                    if #available(SwiftStdlib 5.7, *) {
                      try await Task.sleep(for: .seconds(0.1))
                    } else {
                      try await Task.sleep(nanoseconds: 100_000_000)
                    }
                  #else
                    try await Task.sleep(for: .seconds(0.1))
                  #endif
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
