//
// See LICENSE.txt for license information
//

import Dispatch
import Logging
import NIOCore

#if swift(>=6.0)
  import CNELwIP
#else
  @_implementationOnly import CNELwIP
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
func CNELwIP_IP4_ADDR(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> ip4_addr_t {
  let x = ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((c & 0xff) << 8) | (d & 0xff)
  return ip4_addr_t(addr: lwip_htonl(x))
}

final public class LwIPHandle: PacketHandle, @unchecked Sendable {

  private let v4: LwIPListener
  private let v6: LwIPListener

  let packetFlow: any PacketTunnelFlow

  private let logger = Logger(label: "LwIP")
  private let virtualInterface: UnsafeMutablePointer<netif>?

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
    func cLwIPWriteBridge(
      _ contextPtr: UnsafeMutablePointer<netif>?,
      _ data: UnsafeMutablePointer<pbuf>?,
      _ address: ip_addr_t
    ) {
      guard let opaquePtr = contextPtr?.pointee.state, let data else { return }
      let handle = Unmanaged<LwIPHandle>.fromOpaque(opaquePtr).takeUnretainedValue()
      handle.write(data: data, context: address)
    }

    netif_add(
      virtualInterface, &ipaddr, &netmask, &gw, opaquePtr,
      { contextPtr in
        guard let contextPtr = contextPtr else { return ERR_IF }
        contextPtr.pointee.mtu = 1500
        contextPtr.pointee.mtu6 = 1500
        contextPtr.pointee.output = { contextPtr, bufferPtr, addressPtr in
          guard let pointee = addressPtr?.pointee else { return ERR_OK }
          let address = ip_addr_t(u_addr: .init(ip4: pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
          cLwIPWriteBridge(contextPtr, bufferPtr, address)
          return ERR_OK
        }
        contextPtr.pointee.output_ip6 = { contextPtr, bufferPtr, addressPtr in
          guard let pointee = addressPtr?.pointee else { return ERR_OK }
          let address = ip_addr_t(u_addr: .init(ip6: pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
          cLwIPWriteBridge(contextPtr, bufferPtr, address)
          return ERR_OK
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

  fileprivate func write(data: UnsafeMutablePointer<pbuf>?, context: ip_addr_t) {
    let protocolFamily = context.type == UInt8(IPADDR_TYPE_V4.rawValue) ? AF_INET : AF_INET6
    guard protocolFamily == AF_INET else { return }

    var packetObjects: [IPPacket] = []
    var bufferPtr = data
    while let data = bufferPtr {
      var byteBuffer = ByteBuffer()
      byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.len)) {
        Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.len, 0))
      }
      let v4 = IPPacket.IPv4Packet(data: byteBuffer)
      packetObjects.append(.v4(v4))
      bufferPtr = data.pointee.next
    }
    packetFlow.writePacketObjects(packetObjects)
  }
}

extension LwIPHandle {
  final class LwIPListener {

    private var listener: UnsafeMutablePointer<tcp_pcb>

    init() {
      listener = tcp_new()
      var addr = ip_addr_any
      tcp_bind(listener, &addr, 0)
    }

    deinit {
      tcp_free(listener)
    }

    func start(queue: DispatchQueue) {
      let newLwIPListener = tcp_listen_with_backlog(listener, UInt8(TCP_DEFAULT_LISTEN_BACKLOG))
      guard let newLwIPListener else {
        tcp_close(listener)
        return
      }
      listener = newLwIPListener

      tcp_arg(listener, Unmanaged.passUnretained(self).toOpaque())
      tcp_accept(listener) { contextPtr, connection, error in
        guard error == ERR_OK else { return error }
        guard let contextPtr, let connection else { return ERR_ARG }
        let newConnection = LwIPConnection(wrapped: connection)
        Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue().accept(newConnection)
        return error
      }
    }

    func cancel() {

    }

    private func accept(_ newConnection: LwIPConnection) {
      newConnection.start(on: .global())
      tcp_backlog_accepted(newConnection.wrapped)
    }
  }

  final class LwIPConnection {

    let wrapped: UnsafeMutablePointer<tcp_pcb>

    init(wrapped: UnsafeMutablePointer<tcp_pcb>) {
      self.wrapped = wrapped
    }

    deinit {
      wrapped.pointee.local_ip
    }

    func start(on queue: DispatchQueue) {
      // passRetained object to make sure we hold connection during
      // `wrapped` is alive.
      tcp_arg(wrapped, Unmanaged.passRetained(self).toOpaque())
      tcp_err(wrapped) { opaquePtr, error in
        guard let opaquePtr else { return }
        // When we receive error we should release our connection
        // so .takeRetainedValue() is called, decreases the
        // reference count of the connection.
        Unmanaged<LwIPConnection>
          .fromOpaque(opaquePtr)
          .takeRetainedValue()
          .errorCaught(context: opaquePtr, error: error)
      }
      tcp_recv(wrapped) { opaquePtr, conn, data, error in
        guard error == ERR_OK else { return error }
        guard let opaquePtr, let conn else { return ERR_ARG }
        Unmanaged<LwIPConnection>
          .fromOpaque(opaquePtr)
          .takeUnretainedValue()
          .channelRead(context: opaquePtr, data: data)
        return ERR_OK
      }
    }

    private func channelRead(context: UnsafeMutableRawPointer, data: UnsafeMutablePointer<pbuf>?) {
      var byteBuffer = ByteBuffer()
      var bufferPtr = data
      while let data = bufferPtr {
        byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len)) {
          Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.len, 0))
        }
        bufferPtr = data.pointee.next
      }
      tcp_recved(wrapped, UInt16(byteBuffer.readableBytes))
    }

    private func errorCaught(context: UnsafeMutableRawPointer, error: err_t) {

    }
  }
}
