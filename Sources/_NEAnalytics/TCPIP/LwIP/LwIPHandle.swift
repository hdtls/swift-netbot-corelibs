//
// See LICENSE.txt for license information
//

import Anlzr
import Dispatch
import Logging
import NEAddressProcessing
import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import NIOPosix
#endif

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

struct LwIPError: Error {
  let code: err_t
}

final public class LwIPHandle: PacketHandle, @unchecked Sendable {

  private let v4: LwIPListener
  private let v6: LwIPListener

  let packetFlow: any PacketTunnelFlow

  private let logger = Logger(label: "LwIP")
  private let virtualInterface: UnsafeMutablePointer<netif>?
  private let eventLoop = MultiThreadedEventLoopGroup.singleton.next()

  deinit {
    virtualInterface?.deinitialize(count: MemoryLayout<netif>.size)
    virtualInterface?.deallocate()
  }

  public init(packetFlow: any PacketTunnelFlow) {
    self.packetFlow = packetFlow
    self.v4 = .init(eventLoop: eventLoop)
    self.v6 = .init(eventLoop: eventLoop)

    // Configure network interface in LwIP
    self.virtualInterface = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.virtualInterface?.initialize(to: .init())

    var ipaddr = CNELwIP_IP4_ADDR(198, 18, 0, 1)
    var netmask = CNELwIP_IP4_ADDR(255, 254, 0, 0)
    var gw = CNELwIP_IP4_ADDR(198, 18, 0, 1)

    eventLoop.submit {
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
        self.virtualInterface, &ipaddr, &netmask, &gw, opaquePtr,
        { contextPtr in
          guard let contextPtr = contextPtr else { return ERR_IF }
          contextPtr.pointee.mtu = 1500
          contextPtr.pointee.mtu6 = 1500
          contextPtr.pointee.output = { contextPtr, bufferPtr, addressPtr in
            guard let pointee = addressPtr?.pointee else { return ERR_OK }
            let address = ip_addr_t(
              u_addr: .init(ip4: pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
            cLwIPWriteBridge(contextPtr, bufferPtr, address)
            return ERR_OK
          }
          contextPtr.pointee.output_ip6 = { contextPtr, bufferPtr, addressPtr in
            guard let pointee = addressPtr?.pointee else { return ERR_OK }
            let address = ip_addr_t(
              u_addr: .init(ip6: pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
            cLwIPWriteBridge(contextPtr, bufferPtr, address)
            return ERR_OK
          }
          return ERR_OK
        }, ip_input)
      netif_set_default(self.virtualInterface)
      netif_set_up(self.virtualInterface)
    }

    let timerInterval = TimeAmount.milliseconds(Int64(TCP_TMR_INTERVAL))
    eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: timerInterval) { _ in
      sys_check_timeouts()
    }
  }

  func runIfActive() async throws {
    eventLoop.submit {
      try self.v4.bind0(to: .init(ipAddress: "0.0.0.0", port: 0), promise: nil)
    }
    logger.trace("LwIPHandle start on .global() queue")
  }

  func handle(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    eventLoop.submit {
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
          self.logger.trace("\(msg)")
        #endif

        ip_input(p, self.virtualInterface)
      }
    }
    return .discarded
  }

  fileprivate func write(data: UnsafeMutablePointer<pbuf>?, context: ip_addr_t) {
    eventLoop.assertInEventLoop()

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
