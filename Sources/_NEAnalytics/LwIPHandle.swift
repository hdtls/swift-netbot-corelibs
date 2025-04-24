//
// See LICENSE.txt for license information
//

import Dispatch
import Foundation
import Logging
import NIOCore

#if swift(>=6.0)
  import CNELwIP
#else
  @_implementationOnly import CNELwIP
#endif

final class _NELwIPTCPListener {

  private var listener: UnsafeMutablePointer<tcp_pcb>

  private let logger = Logger(label: "tcp")

  private static func fromOpaque(_ opaque: UnsafeRawPointer!) -> _NELwIPTCPListener {
    Unmanaged<_NELwIPTCPListener>.fromOpaque(opaque).takeUnretainedValue()
  }

  init(using virtualInterface: UnsafePointer<netif>?) {
    listener = tcp_new()
    var addr = ip_addr_any
    tcp_bind(listener, &addr, 0)
  }

  func start(queue: DispatchQueue) {
    guard let newListener = tcp_listen_with_backlog(listener, u8_t(TCP_DEFAULT_LISTEN_BACKLOG))
    else {
      tcp_close(listener)
      return
    }
    listener = newListener

    tcp_arg(listener, UnsafeMutableRawPointer(listener))
    tcp_accept(listener) { context, connection, error in
      _NELwIPTCPListener.fromOpaque(context).accept(
        context: context, connection: connection, error: error)
    }
  }

  func cancel() {

  }

  private func accept(
    context: UnsafeMutableRawPointer?, connection: UnsafeMutablePointer<tcp_pcb>?, error: err_t
  ) -> err_t {
    guard let conn = connection, error == ERR_OK else {
      return error
    }

    tcp_backlog_accepted(context?.assumingMemoryBound(to: tcp_pcb.self))

    logger.trace("")
    _NELwIPConnection(wrapped: conn).start(on: .global())

    return ERR_OK
  }
}

final class _NELwIPConnection {

  private let connection: UnsafeMutablePointer<tcp_pcb>

  private static func fromOpaque(_ opaque: UnsafeRawPointer!) -> _NELwIPConnection {
    Unmanaged<_NELwIPConnection>.fromOpaque(opaque).takeUnretainedValue()
  }

  init(wrapped: UnsafeMutablePointer<tcp_pcb>) {
    self.connection = wrapped
  }

  func start(on queue: DispatchQueue) {
    tcp_arg(connection, UnsafeMutableRawPointer(connection))

    tcp_err(connection) { context, error in
      _NELwIPConnection.fromOpaque(context).errorCaught(context: context, error: error)
    }

    tcp_recv(connection) { context, conn, data, error in
      _NELwIPConnection.fromOpaque(context).channelRead(
        context: context, pcb: conn, data: data, error: error)
    }
  }

  private func channelRead(
    context: UnsafeMutableRawPointer?, pcb: UnsafeMutablePointer<tcp_pcb>?,
    data: UnsafeMutablePointer<pbuf>?, error: err_t
  ) -> err_t {
    guard let data = data, data.pointee.tot_len > 0 else {
      return ERR_ABRT
    }

    var byteBuffer = Data(repeating: .zero, count: Int(data.pointee.tot_len))
    byteBuffer.withUnsafeMutableBytes {
      _ = pbuf_copy_partial(data, $0.baseAddress, data.pointee.tot_len, 0)
    }

    pbuf_free(data)

    tcp_recved(pcb, data.pointee.tot_len)
    return ERR_OK
  }

  private func errorCaught(context: UnsafeMutableRawPointer?, error: err_t) {

  }
}

final public class LwIPHandle: PacketHandle, @unchecked Sendable {

  private let v4: _NELwIPTCPListener
  private let v6: _NELwIPTCPListener? = nil

  var packetFlow: any PacketTunnelFlow
  private let logger = Logger(label: "LwIP")
  private let virtualInterface: UnsafeMutablePointer<netif>?

  private static func fromOpaque(_ opaque: UnsafeMutablePointer<netif>!) -> LwIPHandle {
    Unmanaged<LwIPHandle>.fromOpaque(UnsafeRawPointer(opaque)).takeUnretainedValue()
  }

  deinit {
    virtualInterface?.deinitialize(count: MemoryLayout<netif>.size)
    virtualInterface?.deallocate()
  }

  public init(packetFlow: any PacketTunnelFlow) {
    lwip_init()

    tcp_init()
    // Configure network interface in LwIP
    virtualInterface = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    virtualInterface?.initialize(to: .init())

    func makeIP4Addr(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> ip4_addr_t {
      var ipaddr = ip4_addr_t()
      ipaddr.addr = lwip_htonl(((a) << 24) | ((b) << 16) | ((c) << 8) | (d))
      return ipaddr
    }

    var ipaddr = makeIP4Addr(198, 18, 0, 1)
    var netmask = makeIP4Addr(255, 254, 0, 0)
    var gw = makeIP4Addr(198, 18, 0, 1)

    netif_init()
    netif_add(
      virtualInterface, &ipaddr, &netmask, &gw, nil,
      {
        $0?.pointee.output = { context, p, v4 in
          guard let context, let p, let v4 else {
            return ERR_ARG
          }
          let ipaddr = ip_addr_t(
            u_addr: .init(ip4: v4.pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
          return LwIPHandle.fromOpaque(context).commonOutput(
            netif: context, p: p, ipaddr: ipaddr)
        }
        $0?.pointee.output_ip6 = { context, p, v6 in
          guard let context, let p, let v6 else {
            return ERR_ARG
          }
          let ipaddr = ip_addr_t(
            u_addr: .init(ip6: v6.pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
          return LwIPHandle.fromOpaque(context).commonOutput(
            netif: context, p: p, ipaddr: ipaddr)
        }
        return ERR_OK
      }, ip_input)

    netif_set_default(virtualInterface)
    netif_set_up(virtualInterface)

    self.v4 = _NELwIPTCPListener(using: virtualInterface)

    self.packetFlow = packetFlow
  }

  func runIfActive() async throws {
    v4.start(queue: .global())
    logger.trace("LwIPHandle start on .global() queue")
  }

  func handle(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    packetObject.data.withUnsafeReadableBytes {
      let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
      pbuf_take(p, $0.baseAddress, u16_t($0.count))

      #if DEBUG
        var msg = ""
        switch packetObject {
        case .v4(let packet):
          msg =
            "\(packet.sourceAddress) => \(packet.destinationAddress) \(packet.protocol) \(packet.totalLength) \(packet.data.hexDump(format: .compact(maxBytes: 64)))"
        case .v6:
          //            msg = "\(packet.sourceAddress) => \(packet.destinationAddress) \(packet.protocol) \(packet.totalLength) \(packet.data.hexDump(format: .compact(64)))"
          break
        }
        logger.trace("\(msg)")
      #endif

      ip_input(p, virtualInterface)
    }
    return .discarded
  }

  public func stopTunnel() async {
    v4.cancel()
  }

  private func commonOutput(
    netif: UnsafeMutablePointer<netif>?, p: UnsafeMutablePointer<pbuf>?, ipaddr: ip_addr_t
  ) -> err_t {
    ERR_OK
  }
}
