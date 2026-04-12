//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CoWOptimization
import MaxMindDB
import NEAddressProcessing
import NetbotLite
import NetbotLiteData

/// Forwarding rule base on GeoIP country code.
@available(SwiftStdlib 5.3, *)
@_cowOptimization
struct GeoIPForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  /// MaxMind GeoLite2 database.
  var db: MaxMindDB?

  /// ISO country code.
  var countryCode: String

  var forwardProtocol: any ForwardProtocolConvertible

  let requireIPAddress = true

  var description: String {
    "GEOIP \(countryCode)"
  }

  init(
    db: MaxMindDB?, countryCode: String, forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(db: db, countryCode: countryCode, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let db, let address = connection.originalRequest?.address else { return false }

    func eval(_ address: Address) -> Bool {
      guard case .hostPort(let host, _) = address else { return false }

      switch host {
      case .ipv4, .ipv6:
        let jsonObject = try? db.lookup(ipAddress: "\(host)") as? [String: [String: Any]]
        let country = jsonObject?["country"]
        let countryCode = country?["iso_code"] as? String
        return countryCode == self.countryCode
      default: return false
      }
    }

    guard !eval(address) else { return true }

    guard let resolutions = connection.dnsResolutionReport?.resolutions else { return false }

    for resolution in resolutions {
      for endpoint in resolution.endpoints {
        if eval(endpoint) { return true }
      }
    }

    return false
  }
}

@available(SwiftStdlib 5.3, *)
extension GeoIPForwardingRule._Storage: Hashable {
  static func == (lhs: GeoIPForwardingRule._Storage, rhs: GeoIPForwardingRule._Storage) -> Bool {
    lhs.countryCode == rhs.countryCode
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(countryCode)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 5.3, *)
extension GeoIPForwardingRule._Storage: @unchecked Sendable {}
