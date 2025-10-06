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
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CoWOptimizationMacros)
  import CoWOptimizationMacros

  let testMacros: [String: (Macro & Sendable).Type] = [
    "_cowOptimization": CoWOptimizationMacro.self,
    "_cowOptimizationIgnored": CoWOptimizationIgnoredMacro.self,
    "_cowOptimizationTracked": CoWOptimizationTrackedMacro.self,
  ]
#endif

@Suite struct CopyonWriteMacrosTests {

  #if canImport(CoWOptimizationMacros)
    @Test func coWOptimizationMacro() throws {
      let originalSource =
        """
        @_cowOptimization struct Contact {
          var givenName: String
          var familyName: String
        }
        """

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

    @Test func coWOptimizationIgnoredMacro() throws {
      let originalSource =
        """
        @_cowOptimization struct Contact {
          @_cowOptimizationIgnored var givenName: String
          var familyName: String
        }
        """

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

    @Test func coWOptimizationTrackedMacro() throws {
      let originalSource =
        """
        @_cowOptimization struct Contact {
          @_cowOptimizationTracked var givenName: String
          var familyName: String
        }
        """

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
