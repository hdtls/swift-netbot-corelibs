//
// See LICENSE.txt for license information
//

import SwiftSyntax

extension VariableDeclSyntax {

  var identifierPattern: IdentifierPatternSyntax? {
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)
  }

  var identifier: TokenSyntax? {
    identifierPattern?.identifier
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
    if accessorsMatching({ $0 == .keyword(.get) }).count > 0 {
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

  func isEquivalent(to other: VariableDeclSyntax) -> Bool {
    if isInstance != other.isInstance {
      return false
    }
    return identifier?.text == other.identifier?.text
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

  var isInlinable: Bool {
    attributes.contains {
      guard case .attribute(let attribute) = $0 else {
        return false
      }
      return attribute.attributeName.trimmedDescription == "inlinable"
    }
  }
}
