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
import NIOExtras
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
  private let quiescing: ServerQuiescingHelper
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
    self.quiescing = ServerQuiescingHelper(group: group)
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

    self.listener.handleNewFlow = handleNewFlow
    _ = self.listener.eventLoop.submit {
      try self.listener.pipeline.syncOperations.addHandler(
        self.quiescing.makeServerChannelHandler(channel: self.listener))
    }
  }

  deinit {
    netif_remove(self.device)
    self.device.deinitialize(count: MemoryLayout<netif>.size)
    self.device.deallocate()
  }

  func run() async throws {
    Task { try await run0() }
  }

  func run0() async throws {
    let address = try SocketAddress(ipAddress: "0.0.0.0", port: 0)

    try await eventLoop.submit { netif_set_up(self.device) }.get()

    try await listener.register()
    try await listener.bind(to: address)

    // We must set `packetFlow` to write DNS response to system network stack.
    dns.packetFlow = packetFlow
    packetsReadLoop = Task { [weak self] in
      guard let self else { return }
      await readPacketsIfActive()
    }
    try await listener.closeFuture.get()
  }

  func shutdownGracefully() async throws {
    quiescing.initiateShutdown(promise: nil)
    dns.packetFlow = nil
    try await eventLoop.submit { netif_set_down(self.device) }.get()
    packetsReadLoop?.cancel()
    packetsReadLoop = nil
  }

  private func readPacketsIfActive() async {
    // Packet reading loop should never stopped, unless we cancelled
    // reading task which mean we have already shutdown LwIP service.
    guard !Task.isCancelled else { return }

    do {
      let packetObjects = await packetFlow.readPacketObjects()
      for packetObject in packetObjects {
        try await handleNewPacket(packetObject)
      }
    } catch {
      logger.error("LwIP failed to process IP packets: \(error)")
    }

    await readPacketsIfActive()
  }

  @discardableResult
  private func handleNewPacket(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    guard case .v4(let inhdr) = packetObject.headerFields else {
      return .discarded
    }

    if inhdr.destinationAddress == self.dns.bindAddress {
      if inhdr.protocol == .tcp || inhdr.protocol == .udp, packetObject.payload.count >= 4 {
        let dstPortStartIndex = packetObject.payload.startIndex.advanced(by: 2)
        let port = packetObject.payload.getInteger(at: dstPortStartIndex, as: UInt16.self)
        if port == 53 {
          _ = try await self.dns.handleInput(packetObject)
          return .handled
        }
      }
    }

    @Sendable @inline(__always) func input(_ packetObject: NEPacket) throws {
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

  private func handleNewFlow(_ tun: NIOAsyncChannel<ByteBuffer, ByteBuffer>) {
    Task {
      try await tun.executeThenClose { ti, to in

        guard
          case .hostPort(_, port: let sourcePort) = try tun.channel.remoteAddress?.asAddress(),
          case .hostPort(host: let host, port: let port) = try tun.channel.localAddress?.asAddress()
        else {
          throw AnalyzeError.operationUnsupported
        }

        let destinationAddress: Address
        // Reverse reserved IPs to domain name if needed.
        if case .ipv4(let address) = host, self.dns.availableIPPool.contains(address) {
          // According to our dns proxy settings that every reserved IPs should
          // be able to query PTR records.
          //
          // Consider as invalid connection if we can't query valid PTR records,
          // and close the connection.
          let prefix = "\(address)".split(separator: ".").reversed().joined(separator: ".")
          let name = try? await self.dns.queryPTR(name: "\(prefix).in-addr.arpa").first?.data
          guard let name else {
            throw AnalyzeError.outputStreamEndpointInvalid
          }

          // Update destination address to use original domain name and port.
          destinationAddress = .hostPort(host: .name(name), port: port)
        } else {
          destinationAddress = .hostPort(host: host, port: port)
        }

        let socks = try await ClientBootstrap(group: .shared)
          .channelOption(.allowRemoteHalfClosure, value: true)
          .connect(to: .init(ipAddress: "127.0.0.1", port: 6153)) { socks in
            socks.configureSOCKSConnectionPipeline(destinationAddress: destinationAddress) {
              socks.eventLoop.makeCompletedFuture {
                try socks.pipeline.syncOperations.addHandler(AutoReplyResponse(tun.channel))
                guard let localAddress = socks.localAddress else {
                  throw ChannelError.unknownLocalAddress
                }
                try ProcessResolver.shared.store(
                  localAddress.asAddress(),
                  to: .hostPort(host: "127.0.0.1", port: sourcePort)
                )
                return socks
              }
            }
          }
          .get()

        try await withThrowingTaskGroup { g in
          g.addTask {
            for try await frame in ti {
              try await socks.writeAndFlush(frame)
            }
          }
          try await g.next()
          g.cancelAll()
        }

        try? await socks.close()
        self.logger.trace("LwIP TUN to SOCKSv5 flow completed")
      }
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LwIP {
  final private class AutoReplyResponse: ChannelInboundHandler, Sendable {
    typealias InboundIn = ByteBuffer

    private let connection: any Channel

    init(_ connection: any Channel) {
      self.connection = connection
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
      let buffer = unwrapInboundIn(data)
      connection.writeAndFlush(buffer, promise: nil)
      context.fireChannelRead(data)
    }
  }
}
