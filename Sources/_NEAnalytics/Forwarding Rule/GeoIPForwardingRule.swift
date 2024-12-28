//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import MaxMindDB

/// Forwarding rule base on GeoIP country code.
struct GeoIPForwardingRule: ForwardingRule, ForwardingRuleConvertible, Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var db: MaxMindDB?
    @usableFromInline var countryCode: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(
      db: MaxMindDB? = nil, countryCode: String, forwardProtocol: any ForwardProtocolConvertible
    ) {
      self.db = db
      self.forwardProtocol = forwardProtocol
      self.countryCode = countryCode
    }

    @inlinable func copy() -> _Storage {
      _Storage(db: db, countryCode: countryCode, forwardProtocol: forwardProtocol)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      lhs.countryCode == rhs.countryCode
        && lhs.forwardProtocol.asForwardProtocol().name
          == rhs.forwardProtocol.asForwardProtocol().name
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(countryCode)
      hasher.combine(forwardProtocol.asForwardProtocol().name)
    }
  }

  @usableFromInline var _storage: _Storage

  /// MaxMind GeoLite2 database.
  @inlinable var db: MaxMindDB? {
    get { _storage.db }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.db = newValue
    }
  }

  let requireIPAddress = true

  @inlinable var forwardProtocol: any ForwardProtocolConvertible {
    get { _storage.forwardProtocol }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.forwardProtocol = newValue
    }
  }

  @inlinable var description: String {
    "GEOIP,\(countryCode),\(forwardProtocol.asForwardProtocol().name)"
  }

  /// ISO country code.
  @inlinable var countryCode: String {
    get { _storage.countryCode }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.countryCode = newValue
    }
  }

  @inlinable init(
    db: MaxMindDB?, countryCode: String, forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(db: db, countryCode: countryCode, forwardProtocol: forwardProtocol)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    guard let db else { return false }

    var hasMatched = false
    for resolution in connection.establishmentReport.resolutions {
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

extension GeoIPForwardingRule: @unchecked Sendable {}
