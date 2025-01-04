//
// See LICENSE.txt for license information
//

import Foundation
import Preference

struct SelectionRecordForGroups: Hashable, Codable, RawRepresentable, Sendable {
  private var _storage: [String: String] = [:]

  var rawValue: String {
    guard let data = try? JSONEncoder().encode(_storage) else { return "{}" }
    return String(data: data, encoding: .utf8) ?? "{}"
  }

  init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8) else { return nil }
    guard let result = try? JSONDecoder().decode([String: String].self, from: data) else {
      return nil
    }
    self._storage = result
  }

  init() {}

  mutating func replaceValue(_ value: String, with newValue: String) {
    for (key, v) in _storage where v == value {
      _storage[key] = newValue
    }
  }

  mutating func removeValue(_ value: String) {
    removeValues(CollectionOfOne(value))
  }

  mutating func removeValues<S>(_ values: S) where S: Sequence, S.Element == String {
    for value in values {
      if let position = _storage.firstIndex(where: { $0.value == value }) {
        _storage.remove(at: position)
      }
    }
  }

  mutating func replaceKey(_ key: String, with newKey: String) {
    let value = _storage[key]
    _storage[key] = nil
    _storage[newKey] = value
  }

  mutating func removeKey(_ key: String) {
    _storage[key] = nil
  }

  mutating func removeKeys<S>(_ keys: S) where S: Sequence, S.Element == String {
    for key in keys {
      _storage[key] = nil
    }
  }

  subscript(key: String) -> String? {
    get { _storage[key] }
    set { _storage[key] = newValue }
  }
}

extension SelectionRecordForGroups: PreferenceRepresentable {}
