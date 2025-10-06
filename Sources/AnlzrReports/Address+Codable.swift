//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import NEAddressProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

// swift-format-ignore: AvoidRetroactiveConformances
@available(SwiftStdlib 5.3, *)
extension Address: @retroactive Codable {

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let data = try container.decode(String.self)

    switch data {
    case _ where data.hasPrefix("[hostPort] "):
      let offset = "[hostPort] ".count
      guard data.count > offset else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Address buffer is empty")
      }
      let addressDescription = data.suffix(from: data.index(data.startIndex, offsetBy: offset))

      // IPv6 address contains multiple :, so we can't use firstIndex to split address.
      guard let position = addressDescription.lastIndex(of: ":") else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Port is missing (\(addressDescription))")
      }
      let host = String(addressDescription.prefix(upTo: position))
      guard let port = UInt16(addressDescription.suffix(from: position).dropFirst()) else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Invalid port value (\(addressDescription))")
      }
      self = .hostPort(host: .init(host), port: .init(rawValue: port))
    case _ where data.hasPrefix("[unix] "):
      let offset = "[unix] ".count
      guard data.count > offset else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Address buffer is empty")
      }
      let addressDescription = data.suffix(from: data.index(data.startIndex, offsetBy: offset))
      self = .unix(path: String(addressDescription))
    case _ where data.hasPrefix("[url] "):
      let offset = "[url] ".count
      guard data.count > offset else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Address buffer is empty")
      }
      let addressDescription = data.suffix(from: data.index(data.startIndex, offsetBy: offset))
      guard let url = URL(string: String(addressDescription)) else {
        throw DecodingError.dataCorruptedError(
          in: container, debugDescription: "Invalid URL string \(addressDescription)")
      }
      self = .url(url)
    default:
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad address")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .hostPort(let host, let port):
      try container.encode("[hostPort] \(host.debugDescription):\(port.debugDescription)")
    case .unix(let path):
      try container.encode("[unix] \(path)")
    case .url(let url):
      try container.encode("[url] \(url)")
    }
  }
}
