//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2021 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOConcurrencyHelpers
import NetbotLiteData

@available(SwiftStdlib 5.3, *)
final public class LRUCache<Key, Value> where Key: Hashable {

  private let _represention: Mutex<[Key: Node]>
  private var head: Node?
  private var tail: Node?

  /// The maximum number of values permitted.
  private let capacity: Int

  /// The number of values currently stored in the cache.
  public var count: Int {
    _represention.withLock { $0.count }
  }

  /// A boolean value to determine whether the cache is empty.
  public var isEmpty: Bool {
    _represention.withLock { $0.isEmpty }
  }

  /// Initialize an instance of `LRUCache` with specified `capacity`.
  public init(capacity: Int) {
    self.capacity = capacity
    self._represention = .init(.init(minimumCapacity: capacity))
  }

  /// Set or remove cache value for specified key.
  ///
  /// Remove value from cache if value is `nil` else set new value for key.
  public func setValue(_ value: Value?, forKey key: Key) {
    guard let value = value else {
      removeValue(forKey: key)
      return
    }

    _represention.withLock {
      guard $0[key] == nil else {
        let node = $0[key]!
        node.value = value
        moveToHead(node)
        return
      }

      let node = Node(key: key, value: value)
      $0[key] = node
      prepend(node)

      if $0.count > capacity, let lastNode = tail {
        $0.removeValue(forKey: lastNode.key)
        remove(lastNode)
      }
    }
  }

  /// Remove a value  from the cache and return it.
  @discardableResult
  public func removeValue(forKey key: Key) -> Value? {
    _represention.withLock {
      guard let entry = $0.removeValue(forKey: key) else {
        return nil
      }
      remove(entry)
      return entry.value
    }
  }

  /// Fetch a value from the cache.
  public func value(forKey key: Key) -> Value? {
    _represention.withLock {
      guard let node = $0[key] else {
        return nil
      }
      moveToHead(node)
      return node.value
    }
  }

  /// Remove all values from the cache.
  public func removeAllValues() {
    _represention.withLock {
      $0.removeAll(keepingCapacity: false)
      head = nil
      tail = nil
    }
  }
}

@available(SwiftStdlib 5.3, *)
extension LRUCache {

  fileprivate final class Node {
    let key: Key
    var value: Value
    var next: Node?

    /// To prevent retain cycles, we should use "weak" references to break the strong references between nodes.
    weak var prev: Node?

    init(key: Key, value: Value) {
      self.key = key
      self.value = value
    }
  }

  private func remove(_ node: Node) {
    let prev = node.prev
    let next = node.next

    prev?.next = next
    next?.prev = prev

    if node === head {
      head = next
    }

    if node === tail {
      tail = prev
    }
  }

  private func prepend(_ newElement: Node) {
    newElement.prev = nil
    newElement.next = head

    head?.prev = newElement
    head = newElement

    if tail == nil {
      tail = head
    }
  }

  private func moveToHead(_ node: Node) {
    if node === head { return }
    remove(node)
    prepend(node)
  }
}

@available(SwiftStdlib 5.3, *)
extension LRUCache: @unchecked Sendable {}

@available(SwiftStdlib 5.3, *)
extension LRUCache {

  public func forEach(_ body: ((key: Key, value: Value)) throws -> Void) rethrows {
    try _represention.withLock { _ in
      var head = head

      while let node = head {
        try body((node.key, node.value))
        head = node.next
      }
    }
  }

  /// Returns the first element of the sequence that satisfies the given
  /// predicate.
  public func first(where predicate: ((key: Key, value: Value)) throws -> Bool) rethrows -> (
    key: Key, value: Value
  )? {
    try _represention.withLock { _ in
      var head = head

      while let node = head {
        if try predicate((node.key, node.value)) {
          return (node.key, node.value)
        }
        head = node.next
      }

      return nil
    }
  }
}
