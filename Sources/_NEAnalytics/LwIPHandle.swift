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

  init() {
    listener = tcp_new()
    var addr = ip_addr_any
    tcp_bind(listener, &addr, 0)
  }

  func start(queue: DispatchQueue) {
    let newListener = tcp_listen_with_backlog(listener, UInt8(TCP_DEFAULT_LISTEN_BACKLOG))
    guard let newListener else {
      tcp_close(listener)
      return
    }
    listener = newListener

    let args = Unmanaged<_NELwIPTCPListener>.passUnretained(self).toOpaque()
    tcp_arg(listener, args)
    tcp_accept(listener) { contextPtr, connection, error in
      _NELwIPTCPListener.fromOpaque(contextPtr).accept(connection, error: error)
    }
  }

  func cancel() {

  }

  private func accept(_ newConnection: UnsafeMutablePointer<tcp_pcb>?, error: err_t) -> err_t {
    guard let newConnection, error == ERR_OK else {
      return error
    }

    _NELwIPConnection(wrapped: newConnection).start(on: .global())
    tcp_backlog_accepted(newConnection)
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
    let args = Unmanaged<_NELwIPConnection>.passUnretained(self).toOpaque()
    tcp_arg(connection, args)
    tcp_err(connection) { contextPtr, error in
      _NELwIPConnection.fromOpaque(contextPtr).errorCaught(context: contextPtr, error: error)
    }
    tcp_recv(connection) { contextPtr, conn, data, error in
      _NELwIPConnection.fromOpaque(contextPtr).channelRead(
        context: contextPtr, pcb: conn, data: data, error: error)
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
  private let v6: _NELwIPTCPListener

  let packetFlow: any PacketTunnelFlow

  private let logger = Logger(label: "LwIP")
  private let virtualInterface: UnsafeMutablePointer<netif>?

  fileprivate static func fromOpaque(_ opaque: UnsafeMutablePointer<netif>) -> LwIPHandle {
    Unmanaged<LwIPHandle>.fromOpaque(UnsafeRawPointer(opaque)).takeUnretainedValue()
  }

  deinit {
    virtualInterface?.deinitialize(count: MemoryLayout<netif>.size)
    virtualInterface?.deallocate()
  }

  public init(packetFlow: any PacketTunnelFlow) {
    self.v4 = .init()
    self.v6 = .init()
    self.packetFlow = packetFlow

    // Configure network interface in LwIP
    self.virtualInterface = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.virtualInterface?.initialize(to: .init())

    var ipaddr = CNELwIP_IP4_ADDR(198, 18, 0, 1)
    var netmask = CNELwIP_IP4_ADDR(255, 254, 0, 0)
    var gw = CNELwIP_IP4_ADDR(198, 18, 0, 1)

    let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
    netif_add(
      virtualInterface, &ipaddr, &netmask, &gw, opaquePtr,
      { contextPtr in
        guard let contextPtr = contextPtr else { return ERR_IF }
        contextPtr.pointee.mtu = 1500
        contextPtr.pointee.mtu6 = 1500
        contextPtr.pointee.output = { contextPtr, bufferPtr, addressPtr in
          guard let pointee = addressPtr?.pointee else { return ERR_OK }
          var address = ip_addr_t(u_addr: .init(ip4: pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
          return CNELwIP_common_write(contextPtr, bufferPtr, address)
        }
        contextPtr.pointee.output_ip6 = { contextPtr, bufferPtr, addressPtr in
          guard let pointee = addressPtr?.pointee else { return ERR_OK }
          var address = ip_addr_t(u_addr: .init(ip6: pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
          return CNELwIP_common_write(contextPtr, bufferPtr, address)
        }
        return ERR_OK
      }, ip_input)
    netif_set_default(virtualInterface)
    netif_set_up(virtualInterface)
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

  fileprivate func write(data: UnsafeMutablePointer<pbuf>?, context: ip_addr_t) -> err_t {
    let protocolFamily = context.type == UInt8(IPADDR_TYPE_V4.rawValue) ? AF_INET : AF_INET6
    guard protocolFamily == AF_INET else { return ERR_OK }

    var packetObjects: [IPPacket] = []
    var bufferPtr = data
    while bufferPtr != nil {
      var data = ByteBuffer()
      let bytesToCopy = bufferPtr!.pointee.len
      data.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(bytesToCopy)) { dataPtr in
        Int(pbuf_copy_partial(bufferPtr, dataPtr.baseAddress, bytesToCopy, 0))
      }
      let v4 = IPPacket.IPv4Packet(data: data)
      packetObjects.append(.v4(v4))
      bufferPtr = bufferPtr?.pointee.next
    }

    packetFlow.writePacketObjects(packetObjects)
    return ERR_OK
  }
}

func CNELwIP_IP4_ADDR(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> ip4_addr_t {
  let x = ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((c & 0xff) << 8) | (d & 0xff)
  return ip4_addr_t(addr: lwip_htonl(x))
}

func CNELwIP_common_write(
  _ contextPtr: UnsafeMutablePointer<netif>?, _ bufferPtr: UnsafeMutablePointer<pbuf>?,
  _ address: ip_addr_t
) -> err_t {
  guard let contextPtr else { return ERR_IF }
  guard let bufferPtr else { return ERR_OK }
  let handle = Unmanaged<LwIPHandle>.fromOpaque(UnsafeRawPointer(contextPtr.pointee.state))
    .takeUnretainedValue()
  return handle.write(data: bufferPtr, context: address)
}
