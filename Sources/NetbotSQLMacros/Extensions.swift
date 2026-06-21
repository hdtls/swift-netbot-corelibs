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

  extension VariableDeclSyntax {

    var identifier: TokenSyntax? {
      bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
    }

    var type: TypeSyntax? {
      bindings.first?.typeAnnotation?.type
    }

    func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
      let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
        switch patternBinding.accessorBlock?.accessors {
        case .accessors(let accessors):
          return accessors
        default:
          return nil
        }
      }.flatMap { $0 }
      return accessors.compactMap { accessor in
        if predicate(accessor.accessorSpecifier.tokenKind) {
          return accessor
        } else {
          return nil
        }
      }
    }

    var isInstance: Bool {
      for modifier in modifiers {
        for token in modifier.tokens(viewMode: .all) {
          if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
            return false
          }
        }
      }
      return true
    }

    var isComputed: Bool {
      if !accessorsMatching({ $0 == .keyword(.get) }).isEmpty {
        return true
      } else {
        return bindings.contains { binding in
          if case .getter = binding.accessorBlock?.accessors {
            return true
          } else {
            return false
          }
        }
      }
    }

    var isImmutable: Bool {
      return bindingSpecifier.tokenKind == .keyword(.let)
    }

    var isObservable: Bool {
      !isComputed && isInstance && !isImmutable && identifier != nil
    }

    func hasMacro(named name: String) -> Bool {
      for attribute in attributes {
        switch attribute {
        case .attribute(let attr):
          if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)]
          {
            return true
          }
        default:
          break
        }
      }
      return false
    }
  }
#endif
