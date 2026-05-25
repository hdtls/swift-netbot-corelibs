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

  struct ObservationLockableMacrosTests {

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func lockableMacro() {
      #if canImport(Darwin) || swift(>=6.3)
        let expandedSource = """
          class Contact {
            @ObservationLockableTracked
            var givenName: String
            @ObservationLockableTracked
            var familyName: String

            @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

            package nonisolated func access<Member>(keyPath: KeyPath<Contact, Member>) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<Contact, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }

            private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
              true
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }

            private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs !== rhs
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }
          }

          #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
            @available(SwiftStdlib 5.9, *)
          #else
            @available(SwiftStdlib 6.0, *)
          #endif
          extension Contact: nonisolated Observation.Observable {
          }
          """
      #else
        let expandedSource = """
          class Contact {
            @ObservationLockableTracked
            var givenName: String
            @ObservationLockableTracked
            var familyName: String

            package nonisolated func access<Member>(keyPath: KeyPath<Contact, Member>) {
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<Contact, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try mutation()
            }
          }
          """
      #endif

      assertMacroExpansion(
        """
        @ObservationLockable class Contact {
          var givenName: String
          var familyName: String
        }
        """,
        expandedSource: expandedSource,
        macros: ["ObservationLockable": ObservationLockableMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func lockableMacroIgnoreUnLockableMember() {
      #if canImport(Darwin) || swift(>=6.3)
        let expandedSource = """
          class UnLockable {
            static let name = "UnLockable"
            var name: String { Self.name }
            let tag: Int = 0
            func prepare() {}

            @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

            package nonisolated func access<Member>(keyPath: KeyPath<UnLockable, Member>) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<UnLockable, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }

            private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
              true
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }

            private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs !== rhs
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }
          }

          #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
            @available(SwiftStdlib 5.9, *)
          #else
            @available(SwiftStdlib 6.0, *)
          #endif
          extension UnLockable: nonisolated Observation.Observable {
          }
          """
      #else
        let expandedSource = """
          class UnLockable {
            static let name = "UnLockable"
            var name: String { Self.name }
            let tag: Int = 0
            func prepare() {}

            package nonisolated func access<Member>(keyPath: KeyPath<UnLockable, Member>) {
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<UnLockable, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try mutation()
            }
          }
          """
      #endif
      assertMacroExpansion(
        """
        @ObservationLockable class UnLockable {
          static let name = "UnLockable"
          var name: String { Self.name }
          let tag: Int = 0
          func prepare() {}
        }
        """,
        expandedSource: expandedSource,
        macros: ["ObservationLockable": ObservationLockableMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func lockableMacroIgnoreMemberAlreadyContainsTrackedOrIgnored() {
      #if canImport(Darwin) || swift(>=6.3)
        let expandedSource = """
          class UnLockable {
            @ObservationLockableTracked var tracked: String
            @ObservationLockableIgnored var ignored: Int

            @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

            package nonisolated func access<Member>(keyPath: KeyPath<UnLockable, Member>) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<UnLockable, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }

            private nonisolated func shouldNotifyObservers<Member>(_ lhs: Member, _ rhs: Member) -> Bool {
              true
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }

            private nonisolated func shouldNotifyObservers<Member: AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs !== rhs
            }

            private nonisolated func shouldNotifyObservers<Member: Equatable & AnyObject>(_ lhs: Member, _ rhs: Member) -> Bool {
              lhs != rhs
            }
          }

          #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
            @available(SwiftStdlib 5.9, *)
          #else
            @available(SwiftStdlib 6.0, *)
          #endif
          extension UnLockable: nonisolated Observation.Observable {
          }
          """
      #else
        let expandedSource = """
          class UnLockable {
            @ObservationLockableTracked var tracked: String
            @ObservationLockableIgnored var ignored: Int

            package nonisolated func access<Member>(keyPath: KeyPath<UnLockable, Member>) {
            }

            package nonisolated func withMutation<Member, MutationResult>(keyPath: KeyPath<UnLockable, Member>, _ mutation: () throws -> MutationResult) rethrows -> MutationResult {
              try mutation()
            }
          }
          """
      #endif
      assertMacroExpansion(
        """
        @ObservationLockable class UnLockable {
          @ObservationLockableTracked var tracked: String
          @ObservationLockableIgnored var ignored: Int
        }
        """,
        expandedSource: expandedSource,
        macros: ["ObservationLockable": ObservationLockableMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedMacro() {
      #if canImport(Darwin) || swift(>=6.3)
        let expandedSource = """
          class Tracked {
            var p1: String {
              @storageRestrictions(initializes: $p1)
              init(initialValue) {
                $p1 = .init(initialValue)
              }
              get {
                access(keyPath: \\.p1)
                return self.$p1.withLock {
                  $0
                }
              }
              set {
                let _p1 = self.$p1.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p1, newValue) else {
                  self.$p1.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p1) {
                  self.$p1.withLock {
                    $0 = newValue
                  }
                }
              }
            }

            private let $p1: Mutex<String>
          }
          """
      #else
        let expandedSource = """
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
          """
      #endif
      assertMacroExpansion(
        """
        class Tracked {
          @ObservationLockableTracked var p1: String
        }
        """,
        expandedSource: expandedSource,
        macros: [
          "ObservationLockableTracked": ObservationLockableTrackedMacro.self
        ],
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedWithAccessLevel() {
      #if canImport(Darwin) || swift(>=6.3)
        let expandedSource = """
          class Tracked {
            var p1: Int {
              @storageRestrictions(initializes: $p1)
              init(initialValue) {
                $p1 = .init(initialValue)
              }
              get {
                access(keyPath: \\.p1)
                return self.$p1.withLock {
                  $0
                }
              }
              set {
                let _p1 = self.$p1.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p1, newValue) else {
                  self.$p1.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p1) {
                  self.$p1.withLock {
                    $0 = newValue
                  }
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
                access(keyPath: \\.p2)
                return self.$p2.withLock {
                  $0
                }
              }
              set {
                let _p2 = self.$p2.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p2, newValue) else {
                  self.$p2.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p2) {
                  self.$p2.withLock {
                    $0 = newValue
                  }
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
                access(keyPath: \\.p3)
                return self.$p3.withLock {
                  $0
                }
              }
              set {
                let _p3 = self.$p3.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p3, newValue) else {
                  self.$p3.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p3) {
                  self.$p3.withLock {
                    $0 = newValue
                  }
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
                access(keyPath: \\.p4)
                return self.$p4.withLock {
                  $0
                }
              }
              set {
                let _p4 = self.$p4.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p4, newValue) else {
                  self.$p4.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p4) {
                  self.$p4.withLock {
                    $0 = newValue
                  }
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
                access(keyPath: \\.p5)
                return self.$p5.withLock {
                  $0
                }
              }
              set {
                let _p5 = self.$p5.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p5, newValue) else {
                  self.$p5.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p5) {
                  self.$p5.withLock {
                    $0 = newValue
                  }
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
                access(keyPath: \\.p6)
                return self.$p6.withLock {
                  $0
                }
              }
              set {
                let _p6 = self.$p6.withLock {
                  $0
                }
                guard shouldNotifyObservers(_p6, newValue) else {
                  self.$p6.withLock {
                    $0 = newValue
                  }
                  return
                }
                withMutation(keyPath: \\.p6) {
                  self.$p6.withLock {
                    $0 = newValue
                  }
                }
              }
            }

            private let $p6: Mutex<Int>
          }
          """
      #else
        let expandedSource = """
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
          """
      #endif
      assertMacroExpansion(
        """
        class Tracked {
          @ObservationLockableTracked(accessLevel: .open) var p1: Int
          @ObservationLockableTracked(accessLevel: .public) var p2: Int
          @ObservationLockableTracked(accessLevel: .package) var p3: Int
          @ObservationLockableTracked(accessLevel: .internal) var p4: Int
          @ObservationLockableTracked(accessLevel: .fileprivate) var p5: Int
          @ObservationLockableTracked(accessLevel: .private) var p6: Int
        }
        """,
        expandedSource: expandedSource,
        macros: ["ObservationLockableTracked": ObservationLockableTrackedMacro.self],
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedMacroIgnoreUnLockableProperty() {
      assertMacroExpansion(
        """
        class UnLockable {
          @ObservationLockableTracked static let name = "UnLockable"
          @ObservationLockableTracked var name: String { Self.name }
          @ObservationLockableTracked let tag: Int = 0
          @ObservationLockableTracked func prepare() {}
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
        macros: ["ObservationLockableTracked": ObservationLockableTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedMacroIgnoreAlreadyIgnoredProperty() {
      assertMacroExpansion(
        """
        class UnLockable {
          @ObservationLockableTracked @ObservationLockableIgnored var name: String
        }
        """,
        expandedSource: """
          class UnLockable {
            @ObservationLockableIgnored var name: String
          }
          """,
        macros: ["ObservationLockableTracked": ObservationLockableTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func ignoredMacro() {
      assertMacroExpansion(
        """
        class Ignored {
          @ObservationLockableIgnored var p1: String
        }
        """,
        expandedSource: """
          class Ignored {
            var p1: String
          }
          """,
        macros: ["ObservationLockableIgnored": ObservationLockableIgnoredMacro.self],
      )
    }
  }
#endif
