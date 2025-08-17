//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization
import MaxMindDB
import NEAddressProcessing

/// Forwarding rule base on GeoIP country code.
@_cowOptimization
struct GeoIPForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  /// MaxMind GeoLite2 database.
  var db: MaxMindDB?

  /// ISO country code.
  var countryCode: String

  var forwardProtocol: any ForwardProtocolConvertible

  let requireIPAddress = true

  var description: String {
    "GEOIP,\(countryCode),\(forwardProtocol.asForwardProtocol().name)"
  }

  init(
    db: MaxMindDB?, countryCode: String, forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(db: db, countryCode: countryCode, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let db else { return false }

    guard let resolutions = connection.establishmentReport?.resolutions else {
      return false
    }

    var hasMatched = false

    for resolution in resolutions {
      var address = ""
      switch resolution.preferredEndpoint {
      case .hostPort(let host, port: _):
        switch host {
        case .ipv4(let addr):
          address = addr.debugDescription
        case .ipv6(let addr):
          address = addr.debugDescription
        default:
          continue
        }
      default:
        continue
      }

      let jsonObject = try? db.lookup(ipAddress: address) as? [String: [String: Any]]
      let country = jsonObject?["country"]
      let countryCode = country?["iso_code"] as? String
      hasMatched = countryCode == self.countryCode
      guard hasMatched else {
        continue
      }
      return hasMatched
    }

    return false
  }
}

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

extension GeoIPForwardingRule._Storage: @unchecked Sendable {}
