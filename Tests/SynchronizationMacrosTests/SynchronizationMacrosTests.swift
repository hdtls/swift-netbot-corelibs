// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2025-2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SynchronizationMacros)
  import SynchronizationMacros

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  let testMacros: [String: (Macro & Sendable).Type] = [
    "Lockable": LockableMacro.self,
    "LockableTracked": LockableTrackedMacro.self,
    "LockableIgnored": LockableIgnoredMacro.self,
  ]
#endif

@Suite struct SynchronizationMacrosTests {

  #if canImport(SynchronizationMacros)
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedMacro() throws {
      let originalSource =
        """
        class Tracked {
          @LockableTracked var p1: String
        }
        """

      let expectedExpandedSource = """
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
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedWithAccessMode() throws {
      let originalSource =
        """
        class Tracked {
          @LockableTracked(accessors: .get) var p1: Int
          @LockableTracked(accessors: .get) var p2: Int
          @LockableTracked(accessors: .get, .set) var p3: Int
        }
        """

      let expectedExpandedSource = """
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
          }

          private let $p2: Mutex<Int>
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

          private let $p3: Mutex<Int>
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedWithAccessLevel() throws {
      let originalSource =
        """
        class Tracked {
          @LockableTracked(accessLevel: .open) var p1: Int
          @LockableTracked(accessLevel: .public) var p2: Int
          @LockableTracked(accessLevel: .package) var p3: Int
          @LockableTracked(accessLevel: .internal) var p4: Int
          @LockableTracked(accessLevel: .fileprivate) var p5: Int
          @LockableTracked(accessLevel: .private) var p6: Int
        }
        """

      let expectedExpandedSource = """
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
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func ignoredMacro() throws {
      let originalSource =
        """
        class Ignored {
          @LockableIgnored var p1: String
        }
        """

      let expectedExpandedSource = """
        class Ignored {
          var p1: String
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func lockableMacro() throws {
      let originalSource =
        """
        @Lockable class Contact {
          var givenName: String
          var familyName: String
        }
        """

      let expectedExpandedSource = """
        class Contact {
          var givenName: String {
            @storageRestrictions(initializes: $givenName)
            init(initialValue) {
              $givenName = .init(initialValue)
            }
            get {
              self.$givenName.withLock {
                $0
              }
            }
            set {
              self.$givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let $givenName: Mutex<String>
          var familyName: String {
            @storageRestrictions(initializes: $familyName)
            init(initialValue) {
              $familyName = .init(initialValue)
            }
            get {
              self.$familyName.withLock {
                $0
              }
            }
            set {
              self.$familyName.withLock {
                $0 = newValue
              }
            }
          }

          private let $familyName: Mutex<String>
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func ignoreUnderLockable() throws {
      let originalSource =
        """
        @Lockable class Contact {
          var givenName: String
          @LockableIgnored var familyName: String
        }
        """

      let expectedExpandedSource = """
        class Contact {
          var givenName: String {
            @storageRestrictions(initializes: $givenName)
            init(initialValue) {
              $givenName = .init(initialValue)
            }
            get {
              self.$givenName.withLock {
                $0
              }
            }
            set {
              self.$givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let $givenName: Mutex<String>
          var familyName: String
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedUnderLockable() throws {
      let originalSource =
        """
        @Lockable class Contact {
          @LockableTracked var givenName: String
          var familyName: String
        }
        """

      let expectedExpandedSource = """
        class Contact {
          var givenName: String {
            @storageRestrictions(initializes: $givenName)
            init(initialValue) {
              $givenName = .init(initialValue)
            }
            get {
              self.$givenName.withLock {
                $0
              }
            }
            set {
              self.$givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let $givenName: Mutex<String>
          var familyName: String {
            @storageRestrictions(initializes: $familyName)
            init(initialValue) {
              $familyName = .init(initialValue)
            }
            get {
              self.$familyName.withLock {
                $0
              }
            }
            set {
              self.$familyName.withLock {
                $0 = newValue
              }
            }
          }

          private let $familyName: Mutex<String>
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func trackedWithAccessModeUnderLockable() throws {
      let originalSource =
        """
        @Lockable class Tracked {
          @LockableTracked(accessors: .get) var p1: Int
          @LockableTracked(accessors: .get, .set) var p2: Int
        }
        """

      let expectedExpandedSource = """
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
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func lockableWithDefaultAccessControl() throws {
      let originalSource =
        """
        @Lockable() class Locked {
          var p1: Int
        }
        """

      let expectedExpandedSource = """
        class Locked {
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

          private let $p1: Mutex<Int>
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }
  #endif
}
