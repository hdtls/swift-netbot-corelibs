//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2023 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Atomics
import Logging
import NIOCore
import Testing

@testable import Anlzr

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct StorageTests {

  @Test func createStorage() async throws {
    let storage = Analyzer.Storage(logger: .init(label: ""))
    #expect(storage.storage.isEmpty)
    #expect(storage.logger.label == "")
  }

  @Test func accessStorageWithKey() async throws {
    struct Key: StorageKey {
      typealias Value = _Storage

      final class _Storage: StorageValue, Sendable {}
    }

    var storage = Analyzer.Storage(logger: .init(label: ""))
    #expect(storage[Key.self] == nil)

    let v = Key._Storage()
    storage[Key.self] = v
    #expect(storage[Key.self] === v)

    let v1 = Key._Storage()
    storage[Key.self] = v1
    #expect(storage[Key.self] === v1)

    storage[Key.self] = nil
    #expect(storage[Key.self] == nil)
  }

  @Test func accessStorageWithKeyAndDefaultValue() async throws {
    struct Key: StorageKey {
      typealias Value = _Storage

      final class _Storage: StorageValue, Sendable {}
    }

    var storage = Analyzer.Storage(logger: .init(label: ""))
    #expect(storage[Key.self] == nil)

    let v = Key._Storage()
    #expect(storage[Key.self, default: v] === v)
    #expect(storage[Key.self] === v)
  }

  @Test func runStorageValues() async throws {
    struct Key: StorageKey {
      typealias Value = _Storage

      final class _Storage: StorageValue, Sendable {
        let runCalls = ManagedAtomic<Int>(0)

        func run0() {
          runCalls.wrappingIncrement(ordering: .relaxed)
        }
      }
    }

    var storage = Analyzer.Storage(logger: .init(label: ""))
    let v = Key._Storage()
    storage[Key.self] = v
    #expect(v.runCalls.load(ordering: .relaxed) == 0)
    try await storage.run()
    #expect(v.runCalls.load(ordering: .relaxed) == 1)
  }

  @Test func shutdowStorageValues() async throws {
    struct Key: StorageKey {
      typealias Value = _Storage

      final class _Storage: StorageValue, Sendable {
        let shutdownCalls = ManagedAtomic<Int>(0)

        func shutdownGracefully0() async {
          shutdownCalls.wrappingIncrement(ordering: .relaxed)
        }
      }
    }

    var storage = Analyzer.Storage(logger: .init(label: ""))
    let v = Key._Storage()
    storage[Key.self] = v
    #expect(v.shutdownCalls.load(ordering: .relaxed) == 0)

    await storage.shutdownGracefully()
    #expect(v.shutdownCalls.load(ordering: .relaxed) == 1)
  }

  @Test func automaticallyShutdowOriginalStorageValue() async throws {
    struct Key: StorageKey {
      typealias Value = _Storage

      final class _Storage: StorageValue, Sendable {
        let shutdownCalls = ManagedAtomic<Int>(0)
        let promise: EventLoopPromise<Void>
        init(promise: EventLoopPromise<Void>) {
          self.promise = promise
        }

        func shutdownGracefully0() async {
          shutdownCalls.wrappingIncrement(ordering: .relaxed)
          promise.succeed()
        }
      }
    }

    let promise = MultiThreadedEventLoopGroup.singleton.any().makePromise(of: Void.self)
    var storage = Analyzer.Storage(logger: .init(label: ""))
    let v = Key._Storage(promise: promise)
    storage[Key.self] = v
    #expect(v.shutdownCalls.load(ordering: .relaxed) == 0)

    storage[Key.self] = nil
    try await promise.futureResult.get()
    #expect(v.shutdownCalls.load(ordering: .relaxed) == 1)
  }
}
