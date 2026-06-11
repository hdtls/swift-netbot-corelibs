// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(SynchronizationMacros)
  import SynchronizationMacros
  import Testing

  struct LockableMacrosTests {

    @available(SwiftStdlib 6.0, *)
    @Test func lockableMacro() {
      assertMacroExpansion(
        """
        @Lockable class Contact {
          var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          class Contact {
            @LockableTracked
            var givenName: String
            @LockableTracked
            var familyName: String
          }
          """,
        macros: ["Lockable": LockableMacro.self]
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func lockableMacroIgnoreUnLockableMember() {
      assertMacroExpansion(
        """
        @Lockable class UnLockable {
          static let name = "UnLockable"
          var name: String { Self.name }
          let tag: Int = 0
          func prepare() {}
        }
        """,
        expandedSource: """
          class UnLockable {
            static let name = "UnLockable"
            var name: String { Self.name }
            let tag: Int = 0
            func prepare() {}
          }
          """,
        macros: ["Lockable": LockableMacro.self]
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func lockableMacroIgnoreMemberAlreadyContainsTrackedOrIgnored() {
      assertMacroExpansion(
        """
        @Lockable class UnLockable {
          @LockableTracked var tracked: String
          @LockableIgnored var ignored: Int
        }
        """,
        expandedSource: """
          class UnLockable {
            @LockableTracked var tracked: String
            @LockableIgnored var ignored: Int
          }
          """,
        macros: ["Lockable": LockableMacro.self]
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func trackedMacro() {
      assertMacroExpansion(
        """
        class Tracked {
          @LockableTracked var p1: String
        }
        """,
        expandedSource: """
          class Tracked {
            var p1: String {
              @storageRestrictions(initializes: $p1)
              init(initialValue) {
                $p1 = .init(initialValue)
              }
              get {
                self.$p1.withLock {
                  $0
                }
              }
              set {
                self.$p1.withLock {
                  $0 = newValue
                }
              }
            }

            private let $p1: Mutex<String>
          }
          """,
        macros: [
          "LockableTracked": LockableTrackedMacro.self
        ],
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func trackedWithAccessMode() {
      assertMacroExpansion(
        """
        class Tracked {
          @LockableTracked(accessors: .get) var p1: Int
          @LockableTracked(accessors: .get, .set) var p2: Int
        }
        """,
        expandedSource: """
          class Tracked {
            var p1: Int {
              @storageRestrictions(initializes: $p1)
              init(initialValue) {
                $p1 = .init(initialValue)
              }
              get {
                self.$p1.withLock {
                  $0
                }
              }
            }

            private let $p1: Mutex<Int>
            var p2: Int {
              @storageRestrictions(initializes: $p2)
              init(initialValue) {
                $p2 = .init(initialValue)
              }
              get {
                self.$p2.withLock {
                  $0
                }
              }
              set {
                self.$p2.withLock {
                  $0 = newValue
                }
              }
            }

            private let $p2: Mutex<Int>
          }
          """,
        macros: ["LockableTracked": LockableTrackedMacro.self],
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func trackedWithAccessLevel() {
      assertMacroExpansion(
        """
        class Tracked {
          @LockableTracked(accessLevel: .open) var p1: Int
          @LockableTracked(accessLevel: .public) var p2: Int
          @LockableTracked(accessLevel: .package) var p3: Int
          @LockableTracked(accessLevel: .internal) var p4: Int
          @LockableTracked(accessLevel: .fileprivate) var p5: Int
          @LockableTracked(accessLevel: .private) var p6: Int
        }
        """,
        expandedSource: """
          class Tracked {
            var p1: Int {
              @storageRestrictions(initializes: $p1)
              init(initialValue) {
                $p1 = .init(initialValue)
              }
              get {
                self.$p1.withLock {
                  $0
                }
              }
              set {
                self.$p1.withLock {
                  $0 = newValue
                }
              }
            }

            open let $p1: Mutex<Int>
            var p2: Int {
              @storageRestrictions(initializes: $p2)
              init(initialValue) {
                $p2 = .init(initialValue)
              }
              get {
                self.$p2.withLock {
                  $0
                }
              }
              set {
                self.$p2.withLock {
                  $0 = newValue
                }
              }
            }

            public let $p2: Mutex<Int>
            var p3: Int {
              @storageRestrictions(initializes: $p3)
              init(initialValue) {
                $p3 = .init(initialValue)
              }
              get {
                self.$p3.withLock {
                  $0
                }
              }
              set {
                self.$p3.withLock {
                  $0 = newValue
                }
              }
            }

            package let $p3: Mutex<Int>
            var p4: Int {
              @storageRestrictions(initializes: $p4)
              init(initialValue) {
                $p4 = .init(initialValue)
              }
              get {
                self.$p4.withLock {
                  $0
                }
              }
              set {
                self.$p4.withLock {
                  $0 = newValue
                }
              }
            }

            internal let $p4: Mutex<Int>
            var p5: Int {
              @storageRestrictions(initializes: $p5)
              init(initialValue) {
                $p5 = .init(initialValue)
              }
              get {
                self.$p5.withLock {
                  $0
                }
              }
              set {
                self.$p5.withLock {
                  $0 = newValue
                }
              }
            }

            fileprivate let $p5: Mutex<Int>
            var p6: Int {
              @storageRestrictions(initializes: $p6)
              init(initialValue) {
                $p6 = .init(initialValue)
              }
              get {
                self.$p6.withLock {
                  $0
                }
              }
              set {
                self.$p6.withLock {
                  $0 = newValue
                }
              }
            }

            private let $p6: Mutex<Int>
          }
          """,
        macros: ["LockableTracked": LockableTrackedMacro.self],
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func trackedMacroIgnoreUnLockableProperty() {
      assertMacroExpansion(
        """
        class UnLockable {
          @LockableTracked static let name = "UnLockable"
          @LockableTracked var name: String { Self.name }
          @LockableTracked let tag: Int = 0
          @LockableTracked func prepare() {}
        }
        """,
        expandedSource: """
          class UnLockable {
            static let name = "UnLockable"
            var name: String { Self.name }
            let tag: Int = 0
            func prepare() {}
          }
          """,
        macros: ["LockableTracked": LockableTrackedMacro.self]
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func trackedMacroIgnoreAlreadyIgnoredProperty() {
      assertMacroExpansion(
        """
        class UnLockable {
          @LockableTracked @LockableIgnored var name: String
        }
        """,
        expandedSource: """
          class UnLockable {
            @LockableIgnored var name: String
          }
          """,
        macros: ["LockableTracked": LockableTrackedMacro.self]
      )
    }

    @available(SwiftStdlib 6.0, *)
    @Test func ignoredMacro() {
      assertMacroExpansion(
        """
        class Ignored {
          @LockableIgnored var p1: String
        }
        """,
        expandedSource: """
          class Ignored {
            var p1: String
          }
          """,
        macros: ["LockableIgnored": LockableIgnoredMacro.self],
      )
    }
  }
#endif
