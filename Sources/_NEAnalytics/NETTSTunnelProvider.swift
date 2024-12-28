//
// See LICENSE.txt for license information
//

#if canImport(Darwin) && ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  private import CNETTP
  import Foundation
  public import NetworkExtension

  final public class NETTSTunnelProvider: @unchecked Sendable {

    private weak var packetFlow: NEPacketTunnelFlow?

    private let `protocol` = Mutex("socks5")
    private let listenAddress = Mutex("127.0.0.1")
    private let listenPort = Mutex(6153)

    public var isActive: Bool {
      _isActive.withLock { $0 }
    }
    private let _isActive = Mutex(false)

    public var virtualInterface: NWInterface!

    /// Tunnel device file descriptor.
    private var fd: Int32? {
      var ctlInfo = ctl_info()
      withUnsafeMutablePointer(to: &ctlInfo.ctl_name) {
        $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: $0.pointee)) {
          _ = strcpy($0, "com.apple.net.utun_control")
        }
      }
      for fd: Int32 in 0...1024 {
        var addr = sockaddr_ctl()
        var ret: Int32 = -1
        var len = socklen_t(MemoryLayout.size(ofValue: addr))
        withUnsafeMutablePointer(to: &addr) {
          $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            ret = getpeername(fd, $0, &len)
          }
        }
        if ret != 0 || addr.sc_family != AF_SYSTEM {
          continue
        }
        if ctlInfo.ctl_id == 0 {
          let info: UInt = 0xc064_4e03
          ret = ioctl(fd, info, &ctlInfo)
          if ret != 0 {
            continue
          }
        }
        if addr.sc_id == ctlInfo.ctl_id {
          return fd
        }
      }
      return nil
    }

    public init(packetFlow: NEPacketTunnelFlow) {
      self.packetFlow = packetFlow
    }

    public func startTunnel(options: [String: Any]? = nil) async throws {
      // Do Nothing if tunnel is already active.
      guard !isActive else { return }

      guard let fd else {
        return
      }

      let `protocol` = self.protocol.withLock { $0 }
      let listenAddress = self.listenAddress.withLock { $0 }
      let port = self.listenPort.withLock { UInt16($0) }
      let mtu = options?["MTU"] as? UInt16 ?? 1500

      Task.detached {
        `protocol`.withCString { `protocol` in
          listenAddress.withCString { listenAddress in
            CNETTP_tunnel_provider_start_tunnel_with_options(
              fd,
              `protocol`,
              listenAddress,
              port,
              mtu,
              cnettp_dns_strategy_over_virtual_dns_server,
              cnettp_log_level_trace
            )
          }
        }
      }
    }

    public func stopTunnel() async {
      // Do Nothing if tunnel is inactive.
      guard isActive else { return }

      CNETTP_tunnel_provider_stop_tunnel()
    }

    public func setProfile(_ profile: Profile) async throws {
      self.protocol.withLock {
        $0 = profile.socksListenPort != nil ? "socks5" : "http"
      }
      self.listenAddress.withLock {
        $0 = profile.socksListenPort != nil ? profile.socksListenAddress : profile.httpListenAddress
      }
      self.listenPort.withLock {
        if let port = profile.socksListenPort {
          $0 = port
        } else {
          $0 = profile.httpListenPort ?? 6152
        }
      }
    }

    public func sleep() async {
      // Add code here to get ready to sleep.
    }

    public func wake() {
      // Add code here to wake up.
    }
  }
#endif
