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
  import SwiftSyntaxBuilder
  import SwiftSyntaxMacros

  package struct PersistentModelMacro {}

  extension PersistentModelMacro: MemberMacro {
    package static func expansion(
      of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
      guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
        return []
      }
      let memberGeneric = context.makeUniqueName("Member")
      let mutationGeneric = context.makeUniqueName("MutationResult")
      #if canImport(Darwin) || swift(>=6.3)
        return [
          """
          @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()
          """,
          """
          nonisolated func access<\(memberGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>) {
            _$observationRegistrar.access(self, keyPath: keyPath)
          }
          """,
          """
          nonisolated func withMutation<\(memberGeneric), \(mutationGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>, _ mutation: () throws -> \(mutationGeneric)) rethrows -> \(mutationGeneric) {
            try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
          }
          """,
          """
          private nonisolated func shouldNotifyObservers<\(memberGeneric)>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool {
            true
          }
          """,
          """
          private nonisolated func shouldNotifyObservers<\(memberGeneric): Equatable>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool {
            lhs != rhs
          }
          """,
          """
          private nonisolated func shouldNotifyObservers<\(memberGeneric): AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool {
            lhs !== rhs
          }
          """,
          """
          private nonisolated func shouldNotifyObservers<\(memberGeneric): Equatable & AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool {
            lhs != rhs
          }
          """,
        ]
      #else
        return []
      #endif
    }
  }

  extension PersistentModelMacro: MemberAttributeMacro {
    package static func expansion(
      of node: SwiftSyntax.AttributeSyntax,
      attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
      providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
      in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
      #if canImport(Darwin) || swift(>=6.3)
        guard let property = member.as(VariableDeclSyntax.self), property.isObservable else {
          return []
        }

        return [
          AttributeSyntax(
            attributeName: IdentifierTypeSyntax(
              name: .identifier("ObservationTracked")),
            leftParen: node.arguments != nil ? .leftParenToken() : nil,
            arguments: node.arguments,
            rightParen: node.arguments != nil ? .rightParenToken() : nil
          )
        ]
      #else
        return []
      #endif
    }
  }

  extension PersistentModelMacro: ExtensionMacro {
    package static func expansion(
      of node: SwiftSyntax.AttributeSyntax,
      attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
      providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
      conformingTo protocols: [SwiftSyntax.TypeSyntax],
      in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

      let sendability: DeclSyntax = """
        @available(swift, deprecated: 5.9, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(raw: type.trimmedDescription)'s persistentModelID instead")
        @available(*, unavailable, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(raw: type.trimmedDescription)'s persistentModelID instead")
        extension \(raw: type.trimmedDescription): Sendable {
        }
        """
      #if canImport(Darwin) || swift(>=6.3)
        let decl: DeclSyntax = """
          extension \(raw: type.trimmedDescription): nonisolated Observation.Observable {
          }
          """
        let ext = decl.cast(ExtensionDeclSyntax.self)
        return [ext, sendability.cast(ExtensionDeclSyntax.self)]
      #else
        return [sendability.cast(ExtensionDeclSyntax.self)]
      #endif
    }
  }
#endif
