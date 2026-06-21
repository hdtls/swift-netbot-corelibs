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

    struct RelationshipPropertyMacroTests {

      @available(SwiftStdlib 6.0, *)
      @Test func relationshipPropertyMacroWorks() {
        assertMacroExpansion(
          """
          class Category {
            var tag: Int
            
            @Relationship(., deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 10, originalName: "o_animal", inverse: \\Animal.category, hashModifier: "h")
            var animals: [Animal]
          }
          """,
          expandedSource: """
            class Category {
              var tag: Int

              var animals: [Animal]
            }
            """,
          macros: ["Relationship": RelationshipPropertyMacro.self]
        )
      }
    }
  #endif
#endif
