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

import NIOCore
import Testing

@testable import _NEAnalytics

struct ByteBufferShimsTests {

  @Test func count() async throws {
    let bf = ByteBuffer(bytes: [0, 1])
    #expect(bf.count == 2)
  }

  @Test func isEmpty() async throws {
    let bf1 = ByteBuffer(bytes: [0, 1])
    #expect(!bf1.isEmpty)

    let bf2 = ByteBuffer()
    #expect(bf2.isEmpty)
  }

  @Test func startIndex() async throws {
    let bf = ByteBuffer(bytes: [1, 0, 1])
    #expect(bf.startIndex == 0)
  }

  @Test func endIndex() async throws {
    let bf = ByteBuffer(bytes: [1, 0, 1])
    #expect(bf.endIndex == 3)
  }

  @Test func indexAfter() async throws {
    let bf = ByteBuffer(bytes: [1, 0, 1])
    #expect(bf.index(after: bf.startIndex) == 1)
  }

  @Test func indexBefore() async throws {
    let bf = ByteBuffer(bytes: [1, 0, 1])
    #expect(bf.index(before: bf.endIndex) == 2)
  }

  @Test func indexOffsetBy() async throws {
    let bf = ByteBuffer()
    #expect(bf.index(bf.startIndex, offsetBy: 2) == 2)
  }

  @Test func distanceFromTo() async throws {
    let bf = ByteBuffer(bytes: [0, 1])
    #expect(bf.distance(from: bf.startIndex, to: bf.endIndex) == 2)
  }

  @Test func prefixMaxLength() async throws {
    let bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf.prefix(0) == ByteBuffer())
    #expect(bf.prefix(3) == ByteBuffer(bytes: [0, 1, 2]))
    #expect(bf.prefix(7) == bf)
  }

  @Test func prefixUpTo() async throws {
    let bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf.prefix(upTo: 0) == ByteBuffer())
    #expect(bf.prefix(upTo: 3) == ByteBuffer(bytes: [0, 1, 2]))
  }

  @Test func prefixThrough() async throws {
    let bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf.prefix(through: 0) == ByteBuffer(bytes: [0]))
    #expect(bf.prefix(through: 3) == ByteBuffer(bytes: [0, 1, 2, 3]))
  }

  @Test func suffixFrom() async throws {
    let bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf.suffix(from: 0) == bf)
    #expect(bf.suffix(from: 3) == ByteBuffer(bytes: [3, 4, 5]))
    #expect(bf.suffix(from: 6) == ByteBuffer())
  }

  @Test func subscriptElementAtIndex() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[0] == 0)
    #expect(bf[3] == 3)

    bf[0] = 1
    #expect(bf[0] == 1)
    bf[3] = 1
    #expect(bf[3] == 1)
  }

  @Test func subscriptElementsWithRange() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[0..<0] == ByteBuffer())
    #expect(bf[1..<4] == ByteBuffer(bytes: [1, 2, 3]))

    bf[0..<2] = ByteBuffer(bytes: [])
    #expect(bf == ByteBuffer(bytes: [2, 3, 4, 5]))

    bf[0..<2] = ByteBuffer(bytes: [0, 1, 2, 3, 4])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 4, 5]))

    bf[0..<2] = [0]
    #expect(bf == ByteBuffer(bytes: [0, 2, 3, 4, 4, 5]))

    #expect(bf[0..<2] == [0, 2])
  }

  @Test func subscriptElementsWithClosedRange() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[0...0] == ByteBuffer(bytes: [0]))
    #expect(bf[1...4] == ByteBuffer(bytes: [1, 2, 3, 4]))

    bf[0...2] = ByteBuffer(bytes: [])
    #expect(bf == ByteBuffer(bytes: [3, 4, 5]))

    bf[0...2] = ByteBuffer(bytes: [0, 1, 2])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2]))

    bf[0...2] = []
    #expect(bf == ByteBuffer())

    bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[0...2] == [0, 1, 2])
  }

  @Test func subscriptElementsWithPartialRangeFrom() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[0...] == bf)
    #expect(bf[1...] == ByteBuffer(bytes: [1, 2, 3, 4, 5]))

    bf[4...] = ByteBuffer()
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3]))
    bf[4...] = ByteBuffer(bytes: [4, 5])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5]))
    bf[0...] = ByteBuffer()
    #expect(bf == ByteBuffer())

    bf[0...] = [1, 2]
    #expect(bf == ByteBuffer(bytes: [1, 2]))

    #expect(bf[0...] == [1, 2])
  }

  @Test func subscriptElementsWithPartialRangeThrough() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[...1] == ByteBuffer(bytes: [0, 1]))
    #expect(bf[...5] == bf)

    bf[...2] = ByteBuffer()
    #expect(bf == ByteBuffer(bytes: [3, 4, 5]))

    bf[...2] = ByteBuffer(bytes: [0, 1, 2])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2]))

    bf[...2] = [1, 4]
    #expect(bf == ByteBuffer(bytes: [1, 4]))

    #expect(bf[...1] == [1, 4])
  }

  @Test func subscriptElementsWithPartialRangeUpTo() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf[..<6] == bf)
    #expect(bf[..<3] == ByteBuffer(bytes: [0, 1, 2]))

    bf[..<2] = ByteBuffer()
    #expect(bf == ByteBuffer(bytes: [2, 3, 4, 5]))

    bf[..<2] = ByteBuffer(bytes: [0, 1])
    #expect(bf == ByteBuffer(bytes: [0, 1, 4, 5]))
    bf[..<4] = ByteBuffer()
    #expect(bf == ByteBuffer())

    bf[..<0] = [0, 1, 2, 3, 4]
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4]))

    #expect(bf[..<3] == [0, 1, 2])
  }

  @Test func append() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.append(6)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5, 6]))
  }

  @Test func appendContentsOf() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.append(contentsOf: ByteBuffer(bytes: [6, 7]))
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5, 6, 7]))

    bf.append(contentsOf: [8, 9])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]))
  }

  @Test func insert() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.insert(6, at: 6)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5, 6]))

    bf.insert(7, at: 3)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 7, 3, 4, 5, 6]))
  }

  @Test func insertContentsOf() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.insert(contentsOf: [6, 7], at: 6)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 3, 4, 5, 6, 7]))

    bf.insert(contentsOf: [8, 9], at: 3)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 8, 9, 3, 4, 5, 6, 7]))

    bf.insert(contentsOf: ByteBuffer(bytes: [10, 11]), at: 10)
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 8, 9, 3, 4, 5, 6, 7, 10, 11]))
  }

  @Test func removeElementAtIndex() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    #expect(bf.remove(at: 1) == 1)
    #expect(bf == ByteBuffer(bytes: [0, 2, 3, 4, 5]))
    #expect(bf.remove(at: 4) == 5)
    #expect(bf == ByteBuffer(bytes: [0, 2, 3, 4]))
  }

  @Test func removeSubrange() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.removeSubrange(1..<3)
    #expect(bf == ByteBuffer(bytes: [0, 3, 4, 5]))

    bf.removeSubrange(4..<4)
    #expect(bf == ByteBuffer(bytes: [0, 3, 4, 5]))

    bf.removeSubrange(..<1)
    #expect(bf == ByteBuffer(bytes: [3, 4, 5]))

    bf.removeSubrange(...1)
    #expect(bf == ByteBuffer(bytes: [5]))

    bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.removeSubrange(0...2)
    #expect(bf == ByteBuffer(bytes: [3, 4, 5]))

    bf.removeSubrange(1...)
    #expect(bf == ByteBuffer(bytes: [3]))
  }

  @Test func replaceSubrange() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.replaceSubrange(1..<3, with: [6, 7, 8])
    #expect(bf == ByteBuffer(bytes: [0, 6, 7, 8, 3, 4, 5]))
    bf.replaceSubrange(0..<2, with: [])
    #expect(bf == ByteBuffer(bytes: [7, 8, 3, 4, 5]))

    bf.replaceSubrange(1..<3, with: [1, 2])
    #expect(bf == ByteBuffer(bytes: [7, 1, 2, 4, 5]))

    bf.replaceSubrange(..<1, with: [0])
    #expect(bf == ByteBuffer(bytes: [0, 1, 2, 4, 5]))

    bf.replaceSubrange(..<1, with: ByteBuffer(bytes: [7]))
    #expect(bf == ByteBuffer(bytes: [7, 1, 2, 4, 5]))

    bf.replaceSubrange(...1, with: [0, 0])
    #expect(bf == ByteBuffer(bytes: [0, 0, 2, 4, 5]))

    bf.replaceSubrange(...1, with: ByteBuffer(bytes: [7]))
    #expect(bf == ByteBuffer(bytes: [7, 2, 4, 5]))

    bf.replaceSubrange(3..., with: [])
    #expect(bf == ByteBuffer(bytes: [7, 2, 4]))

    bf.replaceSubrange(3..., with: ByteBuffer(bytes: [4]))
    #expect(bf == ByteBuffer(bytes: [7, 2, 4, 4]))

    bf.replaceSubrange(1...3, with: ByteBuffer(bytes: [4]))
    #expect(bf == ByteBuffer(bytes: [7, 4]))
  }

  @Test func removeAllKeepCapacity() async throws {
    var bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    bf.removeAll()
    #expect(bf.isEmpty)

    bf = ByteBuffer(bytes: [0, 1, 2, 3, 4, 5])
    let capacity = bf.capacity
    bf.removeAll(keepingCapacity: true)
    #expect(bf.isEmpty)
    #expect(bf.capacity == capacity)
  }
}
