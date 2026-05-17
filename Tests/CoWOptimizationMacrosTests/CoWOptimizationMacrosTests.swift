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

#if canImport(CoWOptimizationMacros)
  import SwiftSyntax
  import SwiftSyntaxBuilder
  import SwiftSyntaxMacroExpansion
  import SwiftSyntaxMacros
  import SwiftSyntaxMacrosGenericTestSupport
  import Testing

  // Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
  import CoWOptimizationMacros

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  let testMacros: [String: (Macro & Sendable).Type] = [
    "_cowOptimization": CoWOptimizationMacro.self,
    "_cowOptimizationIgnored": CoWOptimizationIgnoredMacro.self,
    "_cowOptimizationTracked": CoWOptimizationTrackedMacro.self,
  ]

  @Suite(.tags(.swiftmacros))
  struct CopyonWriteMacrosTests {

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
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
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
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
    @Test func coWOptimizationApplyinlinableAttributeCorrectly() throws {
      let originalSource =
        """
        @_cowOptimization struct Contact {
          @inlinable var givenName: String
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
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
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
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
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
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
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
    @Test func cowOptimizationTrackedIgnoreComputedProperty() {
      let originalSource =
        """
        struct Contact {
          @_cowOptimizationTracked var givenName: String { "Jackson" }
          var familyName: String
        }
        """
      let expectedExpandedSource = """
        struct Contact {
          var givenName: String { "Jackson" }
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
    @Test func cowOptimizationTrackedIgnoreImmutableProperty() {
      let originalSource =
        """
        struct Contact {
          @_cowOptimizationTracked let givenName: String = "Jackson"
          var familyName: String
        }
        """
      let expectedExpandedSource = """
        struct Contact {
          let givenName: String = "Jackson"
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
    @Test func cowOptimizationTrackedIgnoreNonInstanceProperty() {
      let originalSource =
        """
        struct Contact {
          @_cowOptimizationTracked static var givenName: String
          var familyName: String
        }
        """
      let expectedExpandedSource = """
        struct Contact {
          static var givenName: String
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
    @Test func coWOptimizationTrackedApplyinlinableAttributeCorrectly() throws {
      let originalSources = [
        """
        @_cowOptimization struct Contact {
          @inlinable @_cowOptimizationTracked var givenName: String
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
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
              yield &self._storage.givenName
            }
          }
          @inlinable
          var familyName: String {
            get {
              return self._storage.familyName
            }
            _modify {
              if !isKnownUniquelyReferenced(&self._storage) {
                self._storage = self._storage.copy()
              }
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
        }
        """
      for originalSource in originalSources {
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
    }

  }
#endif
