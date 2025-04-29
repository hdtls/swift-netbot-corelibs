//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore

// swift-format-ignore: AlwaysUseLowerCamelCase
func c_ne_lwip_initialize(_ stack: LwIPStack) {
  func c_ne_lwip_v4_addres(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) -> ip4_addr_t {
    let x = ((a & 0xff) << 24) | ((b & 0xff) << 16) | ((c & 0xff) << 8) | (d & 0xff)
    return ip4_addr_t(addr: lwip_htonl(x))
  }

  func c_ne_lwip_write_bridge(
    _ contextPtr: UnsafeMutablePointer<netif>?,
    _ data: UnsafeMutablePointer<pbuf>?,
    _ address: ip_addr_t
  ) {
    guard let opaquePtr = contextPtr?.pointee.state else { return }
    let stack = Unmanaged<LwIPStack>.fromOpaque(opaquePtr).takeUnretainedValue()
    stack.eventLoop.assertInEventLoop()

    var packetObjects: [ByteBuffer] = []
    var bufferPtr = data
    while let data = bufferPtr {
      var byteBuffer = ByteBuffer()
      byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.len)) {
        Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.len, 0))
      }
      packetObjects.append(byteBuffer)
      bufferPtr = data.pointee.next
    }

    stack.delegate?.stack(stack, didReceive: packetObjects)
  }

  var ipaddr = c_ne_lwip_v4_addres(198, 18, 0, 1)
  var netmask = c_ne_lwip_v4_addres(255, 254, 0, 0)
  var gw = c_ne_lwip_v4_addres(198, 18, 0, 1)

  let opaquePtr = Unmanaged.passUnretained(stack).toOpaque()

  netif_add(
    stack.device, &ipaddr, &netmask, &gw, opaquePtr,
    { contextPtr in
      guard let contextPtr = contextPtr else { return ERR_IF }
      contextPtr.pointee.mtu = 1500
      contextPtr.pointee.mtu6 = 1500
      contextPtr.pointee.output = { contextPtr, bufferPtr, addressPtr in
        guard let pointee = addressPtr?.pointee else { return ERR_OK }
        let address = ip_addr_t(
          u_addr: .init(ip4: pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
        c_ne_lwip_write_bridge(contextPtr, bufferPtr, address)
        return ERR_OK
      }
      contextPtr.pointee.output_ip6 = { contextPtr, bufferPtr, addressPtr in
        guard let pointee = addressPtr?.pointee else { return ERR_OK }
        let address = ip_addr_t(
          u_addr: .init(ip6: pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
        c_ne_lwip_write_bridge(contextPtr, bufferPtr, address)
        return ERR_OK
      }
      return ERR_OK
    }, ip_input)
  netif_set_default(stack.device)
  netif_set_up(stack.device)
}
