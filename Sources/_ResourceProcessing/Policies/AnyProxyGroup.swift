//
// See LICENSE.txt for license information
//

import CoWOptimization

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@_cowOptimization public struct AnyProxyGroup: Hashable, Sendable {

  /// Name of the policy group.
  public var name: String

  /// Type of the policy group.
  public var kind: Kind

  /// Resource of policies.
  public var resource: Resource

  /// Network measurements.
  public var measurement: Measurement

  /// The group's creation date.
  public var creationDate: Date

  /// Policies included in the policy group.
  public var lazyProxies: [String]

  /// Create an instance of `AnyProxyGroup` with specified name.
  @inlinable public init(name: String = UUID().uuidString) {
    let creationDate: Date
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      creationDate = .now
    } else {
      creationDate = .init()
    }
    self._storage = _Storage(
      name: name,
      kind: .select,
      resource: .init(),
      measurement: .init(),
      creationDate: creationDate,
      lazyProxies: []
    )
  }
}

extension AnyProxyGroup._Storage: Hashable {
  @inlinable static func == (lhs: AnyProxyGroup._Storage, rhs: AnyProxyGroup._Storage) -> Bool {
    return lhs.name == rhs.name
      && lhs.kind == rhs.kind
      && lhs.resource == rhs.resource
      && lhs.measurement == rhs.measurement
      && lhs.creationDate == rhs.creationDate
      && lhs.lazyProxies == rhs.lazyProxies
  }

  @inlinable func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(kind)
    hasher.combine(resource)
    hasher.combine(measurement)
    hasher.combine(creationDate)
    hasher.combine(lazyProxies)
  }
}

extension AnyProxyGroup._Storage: @unchecked Sendable {}
