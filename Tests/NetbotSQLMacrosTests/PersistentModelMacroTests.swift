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

#if !canImport(SwiftData) || !SWTNE_REQUIRES_SQL
  #if canImport(NetbotSQLMacros)
    import NetbotSQLMacros
    import Testing

    struct PersistentModelMacroTests {

      @available(SwiftStdlib 6.0, *)
      @Test func persistentModelMacroWorks() {
        #if canImport(Darwin) || swift(>=6.3)
          assertMacroExpansion(
            """
            @Model class Contact {
              var givenName: String
              var familyName: String
            }
            """,
            expandedSource: """
              class Contact {
                @ObservationTracked
                var givenName: String
                @ObservationTracked
                var familyName: String

                @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()

                nonisolated func access<__macro_local_6MemberfMu_>(keyPath: KeyPath<Contact, __macro_local_6MemberfMu_>) {
                  _$observationRegistrar.access(self, keyPath: keyPath)
                }

                nonisolated func withMutation<__macro_local_6MemberfMu_, __macro_local_14MutationResultfMu_>(keyPath: KeyPath<Contact, __macro_local_6MemberfMu_>, _ mutation: () throws -> __macro_local_14MutationResultfMu_) rethrows -> __macro_local_14MutationResultfMu_ {
                  try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu_>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                  true
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu_: Equatable>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                  lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu_: AnyObject>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                  lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu_, _ rhs: __macro_local_6MemberfMu_) -> Bool {
                  lhs != rhs
                }
              }

              extension Contact: nonisolated Observation.Observable {
              }

              @available(swift, deprecated: 5.9, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use Contact's persistentModelID instead")
              @available(*, unavailable, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use Contact's persistentModelID instead")
              extension Contact: Sendable {
              }
              """,
            macros: ["Model": PersistentModelMacro.self]
          )
        #else
          assertMacroExpansion(
            """
            @Model class Contact {
              var givenName: String
              var familyName: String
            }
            """,
            expandedSource: """
              class Contact {
                var givenName: String
                var familyName: String
              }

              @available(swift, deprecated: 5.9, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use Contact's persistentModelID instead")
              @available(*, unavailable, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use Contact's persistentModelID instead")
              extension Contact: Sendable {
              }
              """,
            macros: ["Model": PersistentModelMacro.self]
          )
        #endif
      }
    }
  #endif
#endif
