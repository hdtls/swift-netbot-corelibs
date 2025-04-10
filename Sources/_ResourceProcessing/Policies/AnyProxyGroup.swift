//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

public struct AnyProxyGroup: Equatable, Hashable, Sendable {

  @usableFromInline final class _Storage: Hashable, @unchecked Sendable {

    /// Name of the policy group.
    @usableFromInline var name: String

    /// Type of the policy group.
    @usableFromInline var kind = Kind.select

    /// Resource of policies.
    @usableFromInline var resource = Resource()

    /// Network measurements.
    @usableFromInline var measurement = Measurement()

    /// The group's creation date.
    @usableFromInline var creationDate: Date

    /// Policies included in the policy group.
    @usableFromInline var lazyProxies: [String]

    @inlinable init(
      name: String, kind: Kind = Kind.select, resource: AnyProxyGroup.Resource = Resource(),
      measurement: AnyProxyGroup.Measurement = Measurement(), creationDate: Date,
      lazyProxies: [String] = []
    ) {
      self.name = name
      self.kind = kind
      self.resource = resource
      self.measurement = measurement
      self.creationDate = creationDate
      self.lazyProxies = lazyProxies
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        name: name, kind: kind, resource: resource, measurement: measurement,
        creationDate: creationDate, lazyProxies: lazyProxies)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
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

  /// Name of the policy group.
  @inlinable public var name: String {
    get { _storage.name }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.name = newValue
    }
  }

  /// Type of the policy group.
  @inlinable public var kind: Kind {
    get { _storage.kind }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.kind = newValue
    }
  }

  /// Resource of policies.
  @inlinable public var resource: Resource {
    get { _storage.resource }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.resource = newValue
    }
  }

  /// Network measurements.
  @inlinable public var measurement: Measurement {
    get { _storage.measurement }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.measurement = newValue
    }
  }

  /// The group's creation date.
  @inlinable public var creationDate: Date {
    get { _storage.creationDate }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.creationDate = newValue
    }
  }

  /// Policies included in the policy group.
  @inlinable public var lazyProxies: [String] {
    get { _storage.lazyProxies }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyProxies = newValue
    }
  }

  @usableFromInline var _storage: _Storage

  /// Create an instance of `AnyProxyGroup` with specified name.
  @inlinable public init(name: String = UUID().uuidString) {
    let creationDate: Date
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      creationDate = .now
    } else {
      creationDate = .init()
    }
    self._storage = _Storage(name: name, creationDate: creationDate)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }
}
