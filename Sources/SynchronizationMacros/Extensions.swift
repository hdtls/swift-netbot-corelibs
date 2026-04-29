// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import SwiftSyntax

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension VariableDeclSyntax {

  var identifierPattern: IdentifierPatternSyntax? {
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)
  }

  var identifier: TokenSyntax? {
    identifierPattern?.identifier
  }

  var accessLevel: TokenSyntax? {
    modifiers.first {
      switch $0.name.tokenKind {
      case .keyword(.open),
        .keyword(.public),
        .keyword(.package),
        .keyword(.private),
        .keyword(.fileprivate),
        .keyword(.internal):
        return true
      default: return false
      }
    }?.name
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

  var isLockable: Bool {
    !isComputed && isInstance && !isImmutable && identifier != nil
  }

  func hasMacro(named name: String) -> Bool {
    for attribute in attributes {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return true
        }
      default:
        break
      }
    }
    return false
  }

  var lockableTrackedMacroArguments: LabeledExprListSyntax? {
    attributes.compactMap {
      guard case .attribute(let attr) = $0 else {
        return Optional<LabeledExprListSyntax>.none
      }
      guard
        attr.attributeName
          .tokens(viewMode: .all)
          .map({ $0.tokenKind }) == [.identifier(LockableMacro.lockableTracked)]
      else {
        return Optional<LabeledExprListSyntax>.none
      }
      return attr.arguments?.as(LabeledExprListSyntax.self)
    }.first
  }
}

extension FunctionCallExprSyntax {

  var parsedArguments: [(label: TokenSyntax?, value: TokenSyntax?)] {
    arguments.compactMap {
      guard let label = $0.label,
        let value = $0.expression.as(
          MemberAccessExprSyntax.self
        )?.declName.baseName
      else {
        return nil
      }
      return (label, value)
    }
  }
}
