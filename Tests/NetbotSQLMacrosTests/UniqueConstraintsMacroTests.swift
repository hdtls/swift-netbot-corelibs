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

    struct UniqueConstraintsMacroTests {

      @available(SwiftStdlib 6.0, *)
      @Test func relationshipPropertyMacroWorks() {
        assertMacroExpansion(
          """
          class Category {
            #Unique<Category>([\\.name])
            var tag: Int
            var name: String
          }
          """,
          expandedSource: """
            class Category {
              var tag: Int
              var name: String
            }
            """,
          macros: ["Unique": UniqueConstraintsMacro.self]
        )
      }
    }
  #endif
#endif
