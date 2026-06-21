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

    struct AttributePropertyMacroTests {

      @available(SwiftStdlib 6.0, *)
      @Test func attributePropertyMacroWorks() {
        assertMacroExpansion(
          """
          class Contact {
            @Attribute(.unique) var givenName: String
            @Attribute(originalName: "family_name") var familyName: String
            @Attribute(hasModifier: "") var address: String
          }
          """,
          expandedSource: """
            class Contact {
              var givenName: String
              var familyName: String
              var address: String
            }
            """,
          macros: ["Attribute": AttributePropertyMacro.self]
        )
      }
    }
  #endif
#endif
