//
// See LICENSE.txt for license information
//

@available(SwiftStdlib 5.3, *)
extension AnyProxy {
  public enum Kind: String, CaseIterable, Codable, Hashable, Sendable {
    case direct
    case rejectTinyGIF = "reject-tinygif"
    case reject
    case https
    case http
    case socks5OverTLS = "socks5-over-tls"
    case socks5
    case shadowsocks = "ss"
    case vmess

    public var localizedName: String {
      switch self {
      case .direct:
        return "DIRECT"
      case .reject:
        return "REJECT"
      case .rejectTinyGIF:
        return "REJECT-TINYGIF"
      case .http:
        return "HTTP"
      case .https:
        return "HTTPS"
      case .socks5:
        return "SOCKS5"
      case .socks5OverTLS:
        return "SOCKS5 over TLS"
      case .shadowsocks:
        return "Shadowsocks"
      case .vmess:
        return "VMESS"
      }
    }

    public var isProxyable: Bool {
      switch self {
      case .direct, .reject, .rejectTinyGIF:
        return false
      case .http, .https, .socks5, .socks5OverTLS, .shadowsocks, .vmess:
        return true
      }
    }

    public var supportTLSSettings: Bool {
      switch self {
      case .https, .socks5OverTLS, .vmess:
        return true
      default:
        return false
      }
    }
  }
}
