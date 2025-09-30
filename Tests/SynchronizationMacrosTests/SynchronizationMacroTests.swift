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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SynchronizationMacros)
  import SynchronizationMacros

  let testMacros: [String: (Macro & Sendable).Type] = [
    "Lockable": LockableMacro.self,
    "LockableTracked": LockableTrackedMacro.self,
    "LockableIgnored": LockableIgnoredMacro.self,
  ]
#endif

final class SynchronizationMacrosTests: XCTestCase {

  func testTrackedMacro() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        class Tracked {
          @LockableTracked var p1: String
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testTrackedWithAccessMode() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        class Tracked {
          @LockableTracked(accessors: .get) var p1: Int
          @LockableTracked(accessors: .get) var p2: Int
          @LockableTracked(accessors: .get, .set) var p3: Int
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testTrackedWithAccessLevel() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
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
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoredMacro() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        class Ignored {
          @LockableIgnored var p1: String
        }
        """
      ]
      let expectedExpandedSource = """
        class Ignored {
          var p1: String
        }
        """
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testLockableMacro() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        @Lockable class Contact {
          var givenName: String
          var familyName: String
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreUnderLockable() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        @Lockable class Contact {
          var givenName: String
          @LockableIgnored var familyName: String
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testTrackedUnderLockable() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        @Lockable class Contact {
          @LockableTracked var givenName: String
          var familyName: String
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testTrackedWithAccessModeUnderLockable() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        @Lockable class Tracked {
          @LockableTracked(accessors: .get) var p1: Int
          @LockableTracked(accessors: .get, .set) var p2: Int
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testLockableWithDefaultAccessControl() async throws {
    #if canImport(SynchronizationMacros)
      let originalSources = [
        """
        @Lockable() class Locked {
          var p1: Int
        }
        """
      ]
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
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
