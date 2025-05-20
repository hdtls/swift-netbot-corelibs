//
// See LICENSE.txt for license information
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CoWOptimizationMacro {
  static let optimizationIgnored = "_cowOptimizationIgnored"
  static let optimizationTracked = "_cowOptimizationTracked"
}

extension CoWOptimizationMacro: MemberMacro {

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    conformingTo protocols: [TypeSyntax],
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      return []
    }

    let properties = structDecl.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }
    .filter(\.optimizable)
    .compactMap {
      (label: $0.identifier!.trimmed, value: $0.type!)
    }

    let className = "_Storage"
    return [
      """
      @usableFromInline final class \(raw: className) {

        \(raw: properties.map { "@usableFromInline var \($0.label): \($0.value)" }.joined(separator: "\n"))

        @inlinable init(
          \(raw: properties.map { "\($0.label): \($0.value)" }.joined(separator: ",\n"))
        ) {
          \(raw: properties.map { "self.\($0.label) = \($0.label)" }.joined(separator: "\n"))
        }

        @inlinable func copy() -> \(raw: className) {
          \(raw: className)(
            \(raw: properties.map { "\($0.label): \($0.label)" }.joined(separator: ",\n"))
          )
        }
      }
      """,
      "@usableFromInline var _storage: \(raw: className)",
      """
      @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
        if !isKnownUniquelyReferenced(&self._storage) {
          self._storage = self._storage.copy()
        }
      }
      """,
    ]
  }
}

extension CoWOptimizationMacro: MemberAttributeMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    MemberDeclaration: DeclSyntaxProtocol,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    attachedTo declaration: Declaration,
    providingAttributesFor member: MemberDeclaration,
    in context: Context
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self),
      property.optimizable,
      property.identifier != nil
    else {
      return []
    }

    // dont apply to ignored properties or properties that are already flagged as tracked
    guard !property.hasMacro(named: CoWOptimizationMacro.optimizationIgnored) else {
      return []
    }

    let inlinable = AttributeSyntax(
      attributeName: IdentifierTypeSyntax(name: .identifier("inlinable"))
    )
    let optimizationTracked = AttributeSyntax(
      attributeName: IdentifierTypeSyntax(
        name: .identifier(CoWOptimizationMacro.optimizationTracked)
      )
    )

    if property.hasMacro(named: CoWOptimizationMacro.optimizationTracked) {
      if property.isInlinable {
        return []
      }
      return [inlinable]
    } else {
      if property.isInlinable {
        return [optimizationTracked]
      }
      return [optimizationTracked, inlinable]
    }
  }
}

public struct CoWOptimizationTrackedMacro: AccessorMacro {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: Declaration,
    in context: Context
  ) throws -> [AccessorDeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self),
      property.optimizable,
      let label = property.identifier?.trimmed
    else {
      return []
    }

    if property.hasMacro(named: CoWOptimizationMacro.optimizationIgnored) {
      return []
    }

    let getter: AccessorDeclSyntax =
      """
      get {
        return self._storage.\(label)
      }
      """

    let modify: AccessorDeclSyntax =
      """
      _modify {
        copyStorageIfNotUniquelyReferenced()
        yield &self._storage.\(label)
      }
      """

    return [getter, modify]
  }
}

public struct CoWOptimizationIgnoredMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    return []
  }
}

extension VariableDeclSyntax {
  fileprivate var optimizable: Bool {
    !isComputed
      && isInstance
      && !isImmutable
      && !hasMacro(named: CoWOptimizationMacro.optimizationIgnored)
      && identifier != nil
      && type != nil
  }
}
