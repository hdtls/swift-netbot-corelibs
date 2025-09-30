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

import Logging

@available(SwiftStdlib 5.3, *)
extension Analyzer {

  public struct Storage: Sendable {

    var storage: [ObjectIdentifier: any StorageValue]

    /// The logger provided to shutdown closure.
    let logger: Logger

    public init(logger: Logger) {
      self.storage = [:]
      self.logger = logger
    }

    public subscript<Key>(_ key: Key.Type) -> Key.Value? where Key: StorageKey {
      get {
        self.storage[ObjectIdentifier(key)] as? Key.Value
      }
      set {
        let key = ObjectIdentifier(key)
        if let newValue {
          self.storage[key] = newValue
        } else if let existing = self.storage[key] {
          self.storage[key] = nil
          Task {
            await existing.shutdownGracefully0()
          }
        }
      }
    }

    public subscript<Key>(
      _ key: Key.Type,
      default defaultValue: @autoclosure () -> Key.Value
    ) -> Key.Value where Key: StorageKey {
      mutating get {
        if let existing = self[key] {
          return existing
        }

        let new = defaultValue()
        self[key] = new
        return new
      }
    }

    func run() async throws {
      try await withThrowingTaskGroup(of: Void.self) { g in
        for value in storage.values {
          g.addTask {
            try await value.run0()
          }
        }
        try await g.waitForAll()
      }
    }

    func shutdownGracefully() async {
      await withTaskGroup(of: Void.self) { g in
        for value in storage.values {
          g.addTask {
            await value.shutdownGracefully0()
          }
        }
        await g.waitForAll()
      }
    }
  }
}

@available(SwiftStdlib 5.3, *)
public protocol StorageValue: Sendable {
  func run0() async throws
  func shutdownGracefully0() async
}

@available(SwiftStdlib 5.3, *)
extension StorageValue {
  public func run0() async throws {}
  public func shutdownGracefully0() async {}
}

/// A key for accessing values in the storage.
@available(SwiftStdlib 5.3, *)
public protocol StorageKey<Value> {

  /// The associated type representing the type of the storage key's
  /// value.
  associatedtype Value: StorageValue
}
