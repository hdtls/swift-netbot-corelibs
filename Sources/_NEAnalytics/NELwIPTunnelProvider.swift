//
// See LICENSE.txt for license information
//

#if canImport(Darwin) && ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  import CNELwIP
  import Dispatch
  import Foundation

  final class _NELwIPTCPListener {

    private var listener: UnsafeMutablePointer<tcp_pcb>

    private static func fromOpaque(_ opaque: UnsafeRawPointer!) -> _NELwIPTCPListener {
      Unmanaged<_NELwIPTCPListener>.fromOpaque(opaque).takeUnretainedValue()
    }

    init(using virtualInterface: UnsafePointer<netif>?) {
      listener = tcp_new()
      tcp_bind_netif(listener, virtualInterface)
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

  final public class NELwIPTunnelProvider: @unchecked Sendable {

    private let v4: _NELwIPTCPListener
    private let v6: _NELwIPTCPListener? = nil

    var packetFlow: any PacketTunnelFlow

    private let virtualInterface: UnsafeMutablePointer<netif>?

    private static func fromOpaque(_ opaque: UnsafeMutablePointer<netif>!) -> NELwIPTunnelProvider {
      Unmanaged<NELwIPTunnelProvider>.fromOpaque(UnsafeRawPointer(opaque)).takeUnretainedValue()
    }

    deinit {
      virtualInterface?.deallocate()
    }

    public init(packetFlow: any PacketTunnelFlow) {
      lwip_init()

      // Configure network interface in LwIP
      virtualInterface = UnsafeMutablePointer.allocate(capacity: MemoryLayout<netif>.size)
      virtualInterface?.initialize(to: .init())

      var ipaddr = [UInt8]([198, 18, 0, 1]).withUnsafeBytes {
        ip4_addr_t(addr: $0.bindMemory(to: UInt32.self).baseAddress!.pointee)
      }

      var netmask = [UInt8]([255, 154, 0, 0]).withUnsafeBytes {
        ip4_addr_t(addr: $0.bindMemory(to: UInt32.self).baseAddress!.pointee)
      }

      var gw = [198, 18, 0, 1].withUnsafeBytes {
        ip4_addr_t(addr: $0.bindMemory(to: UInt32.self).baseAddress!.pointee)
      }

      netif_add(
        virtualInterface, &ipaddr, &netmask, &gw, nil,
        {
          $0?.pointee.output = { netif, p, v4 in
            guard let netif, let p, let v4 else {
              return ERR_ARG
            }
            let ipaddr = ip_addr_t(
              u_addr: .init(ip4: v4.pointee), type: UInt8(IPADDR_TYPE_V4.rawValue))
            return NELwIPTunnelProvider.fromOpaque(netif).commonOutput(
              netif: netif, p: p, ipaddr: ipaddr)
          }
          $0?.pointee.output_ip6 = { netif, p, v6 in
            guard let netif, let p, let v6 else {
              return ERR_ARG
            }
            let ipaddr = ip_addr_t(
              u_addr: .init(ip6: v6.pointee), type: UInt8(IPADDR_TYPE_V6.rawValue))
            return NELwIPTunnelProvider.fromOpaque(netif).commonOutput(
              netif: netif, p: p, ipaddr: ipaddr)
          }
          return ERR_OK
        }, ip_input)

      netif_set_default(virtualInterface)
      netif_set_up(virtualInterface)

      self.v4 = _NELwIPTCPListener(using: virtualInterface)

      self.packetFlow = packetFlow
    }

    public func startTunnel() async throws {
      v4.start(queue: .global())
      print("NELwIPTunnelProvider start on .global() queue")
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
#endif
