// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Dispatch
import Testing

@testable import NetbotLite

@Suite struct LRUCacheTests {

  let iterations = 1000

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeValue() {
    let cache = LRUCache<Int, Int>(capacity: 5)
    #expect(cache.isEmpty)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)
    #expect(cache.removeValue(forKey: 0) == 0)
    #expect(cache.count == 1)
    #expect(!cache.isEmpty)
    #expect(cache.removeValue(forKey: 0) == nil)
    cache.setValue(nil, forKey: 1)
    #expect(cache.isEmpty)

    let cache1 = LRUCache<Int, Int>(capacity: iterations)
    for i in 0..<iterations {
      cache1.setValue(i, forKey: i)
    }
    DispatchQueue.concurrentPerform(iterations: iterations) { i in
      cache1.removeValue(forKey: i)
    }
    #expect(cache1.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeAllValues() {
    let cache = LRUCache<Int, Int>(capacity: 2)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)
    cache.removeAllValues()
    #expect(cache.isEmpty)
    cache.setValue(0, forKey: 0)
    #expect(cache.count == 1)

    DispatchQueue.concurrentPerform(iterations: iterations) { _ in
      cache.setValue(1, forKey: 1)
      cache.removeAllValues()
    }

    #expect(cache.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func getValue() {
    let cache = LRUCache<Int, Int>(capacity: 2)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)
    #expect(cache.value(forKey: 0) == 0)
    #expect(cache.value(forKey: 1) == 1)
    #expect(cache.value(forKey: 2) == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setValueForKey() {
    let cache = LRUCache<Int, Int>(capacity: 2)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)
    cache.setValue(2, forKey: 2)
    cache.setValue(2, forKey: 2)
    cache.setValue(0, forKey: 0)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)

    #expect(cache.count == 2)
    #expect(cache.value(forKey: 0) == 0)
    #expect(cache.value(forKey: 1) == 1)
    #expect(cache.value(forKey: 2) == nil)

    let cache1 = LRUCache<Int, Int>(capacity: iterations)
    DispatchQueue.concurrentPerform(iterations: iterations) { i in
      cache1.setValue(i, forKey: i)
    }
    #expect(cache1.count == iterations)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func loopEntries() {
    let cache = LRUCache<Int, Int>(capacity: 2)
    cache.setValue(0, forKey: 0)
    cache.setValue(1, forKey: 1)

    var results: [Int] = []
    // swift-format-ignore: ReplaceForEachWithForLoop
    cache.forEach {
      results.append($0.key)
      results.append($0.value)
    }

    #expect(results == [1, 1, 0, 0])

    results = []
    cache.setValue(0, forKey: 1)
    // swift-format-ignore: ReplaceForEachWithForLoop
    cache.forEach {
      results.append($0.key)
      results.append($0.value)
    }
    #expect(results == [1, 0, 0, 0])

    results = []
    cache.setValue(2, forKey: 2)
    // swift-format-ignore: ReplaceForEachWithForLoop
    cache.forEach {
      results.append($0.key)
      results.append($0.value)
    }
    #expect(results == [2, 2, 1, 0])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func filterFirst() throws {
    let cache = LRUCache<Int, Int>(capacity: 3)
    cache.setValue(0, forKey: 0)
    cache.setValue(0, forKey: 1)
    cache.setValue(1, forKey: 1)

    var result = try #require(cache.first(where: { $0.key == 1 }))
    #expect(result.key == 1)
    #expect(result.value == 1)

    result = try #require(cache.first(where: { $0.value == 1 }))
    #expect(result.key == 1)
    #expect(result.value == 1)
  }
}
