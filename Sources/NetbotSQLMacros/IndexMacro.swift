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
  import SwiftSyntax
  import SwiftSyntaxMacros

  package struct IndexMacro {}

  extension IndexMacro: DeclarationMacro {
    package static func expansion(
      of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
      in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
      []
    }
  }
#endif
