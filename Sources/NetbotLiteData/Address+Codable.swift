// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

// swift-format-ignore: AvoidRetroactiveConformances
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Address: @retroactive Codable {

  private struct CodingKeys: CodingKey {

    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
      self.init(stringValue: stringValue, intValue: nil)
    }

    init?(intValue: Int) {
      self.init(stringValue: "_\(intValue)", intValue: intValue)
    }

    init(stringValue: String, intValue: Int?) {
      self.stringValue = stringValue
      self.intValue = intValue
    }
  }

  private enum HostPortCodingKeys: CodingKey {
    case host
    case port
  }

  private enum NameCodingKeys: CodingKey {
    case _0
  }

  private enum Ipv4CodingKeys: CodingKey {
    case _0
  }

  private enum Ipv6CodingKeys: CodingKey {
    case _0
  }

  private enum UnixCodingKeys: CodingKey {
    case path
  }

  private enum UrlCodingKeys: CodingKey {
    case _0
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let urlContainer = try? container.nestedContainer(
      keyedBy: UrlCodingKeys.self, forKey: CodingKeys(stringValue: "url", intValue: nil))
    {
      let url = try urlContainer.decode(URL.self, forKey: ._0)
      self = .url(url)
      return
    }

    if let unixContainer = try? container.nestedContainer(
      keyedBy: UnixCodingKeys.self, forKey: CodingKeys(stringValue: "unix", intValue: nil))
    {
      let path = try unixContainer.decode(String.self, forKey: .path)
      self = .unix(path: path)
      return
    }

    let hostPortContainer = try container.nestedContainer(
      keyedBy: HostPortCodingKeys.self, forKey: CodingKeys(stringValue: "hostPort", intValue: nil))
    let port = try Address.Port(rawValue: hostPortContainer.decode(UInt16.self, forKey: .port))
    let hostContainer = try hostPortContainer.nestedContainer(
      keyedBy: CodingKeys.self, forKey: .host)
    if let ipv4Container = try? hostContainer.nestedContainer(
      keyedBy: Ipv4CodingKeys.self, forKey: CodingKeys(stringValue: "ipv4", intValue: nil))
    {
      let decoded = try ipv4Container.decode(String.self, forKey: ._0)
      guard let v4 = IPv4Address(decoded) else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: ipv4Container.codingPath + [Ipv4CodingKeys._0],
            debugDescription:
              "Cannot initialize \(IPv4Address.self) from invalid \(String.self) value \(decoded)"
          )
        )
      }
      self = .hostPort(host: .ipv4(v4), port: port)
    } else if let ipv6Container = try? hostContainer.nestedContainer(
      keyedBy: Ipv6CodingKeys.self, forKey: CodingKeys(stringValue: "ipv6", intValue: nil))
    {
      let decoded = try ipv6Container.decode(String.self, forKey: ._0)
      guard let v6 = IPv6Address(decoded) else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: ipv6Container.codingPath + [Ipv6CodingKeys._0],
            debugDescription:
              "Cannot initialize \(IPv6Address.self) from invalid \(String.self) value \(decoded)"
          )
        )
      }
      self = .hostPort(host: .ipv6(v6), port: port)
    } else {
      let nameContainer = try hostContainer.nestedContainer(
        keyedBy: NameCodingKeys.self, forKey: CodingKeys(stringValue: "name", intValue: nil))
      let name = try nameContainer.decode(String.self, forKey: ._0)
      self = .hostPort(host: .name(name), port: port)
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .hostPort(let host, let port):
      var hostPortContainer = container.nestedContainer(
        keyedBy: HostPortCodingKeys.self, forKey: CodingKeys(stringValue: "hostPort", intValue: nil)
      )
      var hostContainer = hostPortContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .host)
      switch host {
      case .name(let name):
        var nameContainer = hostContainer.nestedContainer(
          keyedBy: NameCodingKeys.self, forKey: CodingKeys(stringValue: "name", intValue: nil))
        try nameContainer.encode(name, forKey: ._0)
      case .ipv4(let v4):
        var ipv4Container = hostContainer.nestedContainer(
          keyedBy: Ipv4CodingKeys.self, forKey: CodingKeys(stringValue: "ipv4", intValue: nil))
        try ipv4Container.encode(v4.debugDescription, forKey: ._0)
      case .ipv6(let v6):
        var ipv6Container = hostContainer.nestedContainer(
          keyedBy: Ipv6CodingKeys.self, forKey: CodingKeys(stringValue: "ipv6", intValue: nil))
        try ipv6Container.encode(v6.debugDescription, forKey: ._0)
      }
      try hostPortContainer.encode(port.rawValue, forKey: .port)
    case .unix(let path):
      var unixContainer = container.nestedContainer(
        keyedBy: UnixCodingKeys.self, forKey: CodingKeys(stringValue: "unix", intValue: nil))
      try unixContainer.encode(path, forKey: .path)
    case .url(let url):
      var urlContainer = container.nestedContainer(
        keyedBy: UrlCodingKeys.self, forKey: CodingKeys(stringValue: "url", intValue: nil))
      try urlContainer.encode(url, forKey: ._0)
    }
  }
}
