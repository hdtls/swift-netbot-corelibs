//
// See LICENSE.txt for license information
//

import CNELwIP
import NEAddressProcessing
import NIOCore

class LwIP {

  private let packetFlow: any PacketTunnelFlow

  private let device: UnsafeMutablePointer<netif>

  init(
    packetFlow: any PacketTunnelFlow,
    address: IPv4Address,
    netmask: IPv4Address,
    gateway: IPv4Address
  ) {
    self.packetFlow = packetFlow

    lwip_init()

    self.device = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
    self.device.initialize(to: .init())

    var _ipaddr = ip_addr_any
    try! LwIP.inet_aton(address.debugDescription, &_ipaddr)

    var _netmask = ip_addr_any
    try! LwIP.inet_aton(netmask.debugDescription, &_netmask)

    var _gateway = ip_addr_any
    try! LwIP.inet_aton(gateway.debugDescription, &_gateway)

    netif_add(
      self.device, &_ipaddr.u_addr.ip4, &_netmask.u_addr.ip4, &_gateway.u_addr.ip4,
      Unmanaged.passUnretained(self).toOpaque(),
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

          let device = Unmanaged<LwIP>.fromOpaque(opaquePtr).takeUnretainedValue()

          var byteBuffer = ByteBuffer()
          byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len)) {
            Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.tot_len, 0))
          }
          guard let packetObject = NEPacket(data: byteBuffer, protocolFamily: .inet) else {
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
    netif_set_up(self.device)
  }

  deinit {
    self.device.deinitialize(count: MemoryLayout<netif>.size)
    self.device.deallocate()
  }

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

  func handleInput(_ packetObject: NEPacket) throws {
    try packetObject.data.withUnsafeReadableBytes {
      let p = pbuf_alloc(PBUF_IP, u16_t($0.count), PBUF_RAM)
      pbuf_take(p, $0.baseAddress, u16_t($0.count))
      let errno = err_to_errno(self.device.pointee.input(p, self.device))
      guard errno != 0 else {
        return
      }
      pbuf_free(p)
      throw IOError(errnoCode: errno, reason: #function)
    }
  }
}
