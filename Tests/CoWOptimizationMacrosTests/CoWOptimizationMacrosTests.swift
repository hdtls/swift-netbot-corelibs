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
  import CoWOptimizationMacros
  import Testing

  @Suite(.tags(.swiftmacros))
  struct CopyonWriteMacrosTests {

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationMacro() throws {
      assertMacroExpansion(
        """
        @_cowOptimization struct Contact {
          var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            @_cowOptimizationTracked @inlinable
            var givenName: String
            @_cowOptimizationTracked @inlinable
            var familyName: String

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
          """,
        macros: ["_cowOptimization": CoWOptimizationMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationMacroIgnoreNonStructDecl() throws {
      assertMacroExpansion(
        """
        @_cowOptimization class Contact {
          var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          class Contact {
            @_cowOptimizationTracked @inlinable
            var givenName: String
            @_cowOptimizationTracked @inlinable
            var familyName: String
          }
          """,
        macros: ["_cowOptimization": CoWOptimizationMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationMacroIgnoreUnOptimizableMembers() throws {
      assertMacroExpansion(
        """
        @_cowOptimization struct Contact {
          static var name: String { "name" }
          var name: String { Self.name }
          let con: Int = 0
          func dialog() {}
          var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            static var name: String { "name" }
            var name: String { Self.name }
            let con: Int = 0
            func dialog() {}
            @_cowOptimizationTracked @inlinable
            var givenName: String
            @_cowOptimizationTracked @inlinable
            var familyName: String

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
          """,
        macros: ["_cowOptimization": CoWOptimizationMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationApplyinlinableAttributeCorrectly() throws {
      assertMacroExpansion(
        """
        @_cowOptimization struct Contact {
          @inlinable var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            @inlinable
            @_cowOptimizationTracked var givenName: String
            @_cowOptimizationTracked @inlinable
            var familyName: String

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
          """,
        macros: ["_cowOptimization": CoWOptimizationMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationIgnoreMembersAlreadyContainsTrackedAndIgnoredMacro() throws {
      assertMacroExpansion(
        """
        @_cowOptimization struct Contact {
          @_cowOptimizationIgnored var givenName: String
          @_cowOptimizationTracked var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            @_cowOptimizationIgnored var givenName: String
            @_cowOptimizationTracked
            @inlinable var familyName: String

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
          """,
        macros: ["_cowOptimization": CoWOptimizationMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func coWOptimizationTrackedMacro() throws {
      assertMacroExpansion(
        """
        struct Contact {
          @_cowOptimizationTracked var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
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
            var familyName: String
          }
          """,
        macros: ["_cowOptimizationTracked": CoWOptimizationTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func cowOptimizationTrackedIgnoreComputedProperty() {
      assertMacroExpansion(
        """
        struct Contact {
          @_cowOptimizationTracked var givenName: String { "Jackson" }
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            var givenName: String { "Jackson" }
            var familyName: String
          }
          """,
        macros: ["_cowOptimizationTracked": CoWOptimizationTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func cowOptimizationTrackedIgnoreImmutableProperty() {
      assertMacroExpansion(
        """
        struct Contact {
          @_cowOptimizationTracked let givenName: String = "Jackson"
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            let givenName: String = "Jackson"
            var familyName: String
          }
          """,
        macros: ["_cowOptimizationTracked": CoWOptimizationTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func cowOptimizationTrackedIgnoreNonInstanceProperty() {
      assertMacroExpansion(
        """
        struct Contact {
          @_cowOptimizationTracked static var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            static var givenName: String
            var familyName: String
          }
          """,
        macros: ["_cowOptimizationTracked": CoWOptimizationTrackedMacro.self]
      )
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func cowOptimizationIgnoreMacro() {
      assertMacroExpansion(
        """
        struct Contact {
          @_cowOptimizationIgnored var givenName: String
          var familyName: String
        }
        """,
        expandedSource: """
          struct Contact {
            var givenName: String
            var familyName: String
          }
          """,
        macros: ["_cowOptimizationIgnored": CoWOptimizationIgnoredMacro.self]
      )
    }
  }
#endif
