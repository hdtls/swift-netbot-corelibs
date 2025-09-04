//
// See LICENSE.txt for license information
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CoWOptimizationMacros)
  import CoWOptimizationMacros

  let testMacros: [String: (Macro & Sendable).Type] = [
    "_cowOptimization": CoWOptimizationMacro.self,
    "_cowOptimizationIgnored": CoWOptimizationIgnoredMacro.self,
    "_cowOptimizationTracked": CoWOptimizationTrackedMacro.self,
  ]
#endif

final class CopyonWriteMacrosTests: XCTestCase {

  func testCoWOptimizationMacro() throws {
    #if canImport(CoWOptimizationMacros)
      let originalSources = [
        """
        @_cowOptimization struct Contact {
          var givenName: String
          var familyName: String
        }
        """
      ]
      let expectedExpandedSource = """
        struct Contact {
          @inlinable
          var givenName: String {
            get {
              return self._storage.givenName
            }
            _modify {
              copyStorageIfNotUniquelyReferenced()
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              copyStorageIfNotUniquelyReferenced()
              yield &self._storage.familyName
            }
          }

          @usableFromInline final class _Storage {

            @usableFromInline var givenName: String
            @usableFromInline var familyName: String

            @inlinable init(
              givenName: String,
              familyName: String
            ) {
              self.givenName = givenName
              self.familyName = familyName
            }

            @inlinable func copy() -> _Storage {
              _Storage(
                givenName: givenName,
                familyName: familyName
              )
            }
          }

          @usableFromInline var _storage: _Storage

          @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
            if !isKnownUniquelyReferenced(&self._storage) {
              self._storage = self._storage.copy()
            }
          }
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

  func testCoWOptimizationIgnoredMacro() throws {
    #if canImport(CoWOptimizationMacros)
      let originalSources = [
        """
        @_cowOptimization struct Contact {
          @_cowOptimizationIgnored var givenName: String
          var familyName: String
        }
        """
      ]
      let expectedExpandedSource = """
        struct Contact {
          var givenName: String
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              copyStorageIfNotUniquelyReferenced()
              yield &self._storage.familyName
            }
          }

          @usableFromInline final class _Storage {

            @usableFromInline var familyName: String

            @inlinable init(
              familyName: String
            ) {
              self.familyName = familyName
            }

            @inlinable func copy() -> _Storage {
              _Storage(
                familyName: familyName
              )
            }
          }

          @usableFromInline var _storage: _Storage

          @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
            if !isKnownUniquelyReferenced(&self._storage) {
              self._storage = self._storage.copy()
            }
          }
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

  func testCoWOptimizationTrackedMacro() throws {
    #if canImport(CoWOptimizationMacros)
      let originalSources = [
        """
        @_cowOptimization struct Contact {
          @_cowOptimizationTracked var givenName: String
          var familyName: String
        }
        """
      ]
      let expectedExpandedSource = """
        struct Contact {
          @inlinable var givenName: String {
            get {
              return self._storage.givenName
            }
            _modify {
              copyStorageIfNotUniquelyReferenced()
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              copyStorageIfNotUniquelyReferenced()
              yield &self._storage.familyName
            }
          }

          @usableFromInline final class _Storage {

            @usableFromInline var givenName: String
            @usableFromInline var familyName: String

            @inlinable init(
              givenName: String,
              familyName: String
            ) {
              self.givenName = givenName
              self.familyName = familyName
            }

            @inlinable func copy() -> _Storage {
              _Storage(
                givenName: givenName,
                familyName: familyName
              )
            }
          }

          @usableFromInline var _storage: _Storage

          @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
            if !isKnownUniquelyReferenced(&self._storage) {
              self._storage = self._storage.copy()
            }
          }
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
