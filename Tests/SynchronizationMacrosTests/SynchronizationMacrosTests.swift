// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SynchronizationMacros)
  import SynchronizationMacros

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
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
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._p1.withLock {
                $0
              }
            }
            set {
              self._p1.withLock {
                $0 = newValue
              }
            }
          }

          private let _p1: Mutex<String>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._p1.withLock {
                $0
              }
            }
          }

          private let _p1: Mutex<Int>
          var p2: Int {
            get {
              self._p2.withLock {
                $0
              }
            }
          }

          private let _p2: Mutex<Int>
          var p3: Int {
            get {
              self._p3.withLock {
                $0
              }
            }
            set {
              self._p3.withLock {
                $0 = newValue
              }
            }
          }

          private let _p3: Mutex<Int>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._p1.withLock {
                $0
              }
            }
            set {
              self._p1.withLock {
                $0 = newValue
              }
            }
          }

          open let _p1: Mutex<Int>
          var p2: Int {
            get {
              self._p2.withLock {
                $0
              }
            }
            set {
              self._p2.withLock {
                $0 = newValue
              }
            }
          }

          public let _p2: Mutex<Int>
          var p3: Int {
            get {
              self._p3.withLock {
                $0
              }
            }
            set {
              self._p3.withLock {
                $0 = newValue
              }
            }
          }

          package let _p3: Mutex<Int>
          var p4: Int {
            get {
              self._p4.withLock {
                $0
              }
            }
            set {
              self._p4.withLock {
                $0 = newValue
              }
            }
          }

          internal let _p4: Mutex<Int>
          var p5: Int {
            get {
              self._p5.withLock {
                $0
              }
            }
            set {
              self._p5.withLock {
                $0 = newValue
              }
            }
          }

          fileprivate let _p5: Mutex<Int>
          var p6: Int {
            get {
              self._p6.withLock {
                $0
              }
            }
            set {
              self._p6.withLock {
                $0 = newValue
              }
            }
          }

          private let _p6: Mutex<Int>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._givenName.withLock {
                $0
              }
            }
            set {
              self._givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let _givenName: Mutex<String>
          var familyName: String {
            get {
              self._familyName.withLock {
                $0
              }
            }
            set {
              self._familyName.withLock {
                $0 = newValue
              }
            }
          }

          private let _familyName: Mutex<String>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._givenName.withLock {
                $0
              }
            }
            set {
              self._givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let _givenName: Mutex<String>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._givenName.withLock {
                $0
              }
            }
            set {
              self._givenName.withLock {
                $0 = newValue
              }
            }
          }

          private let _givenName: Mutex<String>
          var familyName: String {
            get {
              self._familyName.withLock {
                $0
              }
            }
            set {
              self._familyName.withLock {
                $0 = newValue
              }
            }
          }

          private let _familyName: Mutex<String>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._p1.withLock {
                $0
              }
            }
          }

          private let _p1: Mutex<Int>
          var p2: Int {
            get {
              self._p2.withLock {
                $0
              }
            }
            set {
              self._p2.withLock {
                $0 = newValue
              }
            }
          }

          private let _p2: Mutex<Int>
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
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
            get {
              self._p1.withLock {
                $0
              }
            }
            set {
              self._p1.withLock {
                $0 = newValue
              }
            }
          }

          private let _p1: Mutex<Int>
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
