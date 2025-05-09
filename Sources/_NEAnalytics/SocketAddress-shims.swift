//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension Address {

  var address: SocketAddress {
    get throws {
      switch self {
      case .hostPort(let host, let port):
        switch host {
        case .name(let string):
          return try SocketAddress.makeAddressResolvingHost(string, port: Int(port.rawValue))
        case .ipv4(let v4):
          return try SocketAddress(ipAddress: v4.debugDescription, port: Int(port.rawValue))
        case .ipv6(let v6):
          return try SocketAddress(ipAddress: v6.debugDescription, port: Int(port.rawValue))
        }
      case .unix(let path):
        return try SocketAddress(unixDomainSocketPath: path)
      case .url(let url):
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
          guard let host = url.host(percentEncoded: false), let port = url.port else {
            throw SocketAddressError.unsupported
          }
          return try SocketAddress.makeAddressResolvingHost(host, port: port)
        } else {
          guard let host = url.host, let port = url.port else {
            throw SocketAddressError.unsupported
          }
          return try SocketAddress.makeAddressResolvingHost(host, port: port)
        }
      }
    }
  }
}
