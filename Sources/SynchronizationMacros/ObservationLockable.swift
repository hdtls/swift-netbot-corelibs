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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ObservationLockableMacro: Sendable {
  static let prefixed = "$"
  static let lockable = "ObservationLockable"
  static let lockableTracked = "ObservationLockableTracked"
  static let lockableIgnored = "ObservationLockableIgnored"
}

extension ObservationLockableMacro: MemberMacro {
  public static func expansion(
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
        package nonisolated func access<\(memberGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>) {
          _$observationRegistrar.access(self, keyPath: keyPath)
        }
        """,
        """
        package nonisolated func withMutation<\(memberGeneric), \(mutationGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>, _ mutation: () throws -> \(mutationGeneric)) rethrows -> \(mutationGeneric) {
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
      return [
        """
        package nonisolated func access<\(memberGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>) {
        }
        """,
        """
        package nonisolated func withMutation<\(memberGeneric), \(mutationGeneric)>(keyPath: KeyPath<\(raw: classDecl.name.trimmedDescription), \(memberGeneric)>, _ mutation: () throws -> \(mutationGeneric)) rethrows -> \(mutationGeneric) {
          try mutation()
        }
        """,
      ]
    #endif
  }
}

extension ObservationLockableMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol, in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self), property.isLockable else {
      return []
    }

    if property.hasMacro(named: ObservationLockableMacro.lockableTracked)
      || property.hasMacro(named: ObservationLockableMacro.lockableIgnored)
    {
      return []
    }

    return [
      AttributeSyntax(
        attributeName: IdentifierTypeSyntax(
          name: .identifier(ObservationLockableMacro.lockableTracked)),
        leftParen: node.arguments != nil ? .leftParenToken() : nil,
        arguments: node.arguments,
        rightParen: node.arguments != nil ? .rightParenToken() : nil
      )
    ]
  }
}

#if canImport(Darwin) || swift(>=6.3)
  extension ObservationLockableMacro: ExtensionMacro {
    public static func expansion(
      of node: SwiftSyntax.AttributeSyntax,
      attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
      providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
      conformingTo protocols: [SwiftSyntax.TypeSyntax],
      in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
      let decl: DeclSyntax = """
        @available(SwiftStdlib 6.0, *)
        extension \(raw: type.trimmedDescription): nonisolated Observation.Observable {
        }
        """
      let ext = decl.cast(ExtensionDeclSyntax.self)
      return [ext]
    }
  }
#endif

public struct ObservationLockableTrackedMacro: AccessorMacro, Sendable {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: Declaration,
    in context: Context
  ) throws -> [AccessorDeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self), property.isLockable,
      let label = property.identifier?.trimmed
    else {
      return []
    }

    guard !property.hasMacro(named: ObservationLockableMacro.lockableIgnored) else {
      return []
    }

    #if canImport(Darwin) || swift(>=6.3)
      return [
        """
        @storageRestrictions(initializes: \(raw: ObservationLockableMacro.prefixed)\(label))
        init(initialValue) {
          \(raw: ObservationLockableMacro.prefixed)\(label) = .init(initialValue)
        }
        """,
        """
        get {
          access(keyPath: \\.\(label))
          return self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock {
            $0
          }
        }
        """,
        """
        set {
          let _\(label) = self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock { $0 }
          guard shouldNotifyObservers(_\(label), newValue) else {
            self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock {
              $0 = newValue
            }
            return
          }
          withMutation(keyPath: \\.\(label)) {
            self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock {
              $0 = newValue
            }
          }
        }
        """,
      ]
    #else
      return [
        """
        @storageRestrictions(initializes: \(raw: ObservationLockableMacro.prefixed)\(label))
        init(initialValue) {
          \(raw: ObservationLockableMacro.prefixed)\(label) = .init(initialValue)
        }
        """,
        """
        get {
          self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock {
            $0
          }
        }
        """,
        """
        set {
          self.\(raw: ObservationLockableMacro.prefixed)\(label).withLock {
            $0 = newValue
          }
        }
        """,
      ]
    #endif
  }
}

extension ObservationLockableTrackedMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self),
      property.isLockable,
      let label = property.identifier?.trimmed
    else {
      return []
    }

    if property.hasMacro(named: ObservationLockableMacro.lockableIgnored) {
      return []
    }

    let userDefinedAccessLevel: TokenSyntax =
      node.arguments?.as(LabeledExprListSyntax.self)?.compactMap {
        guard $0.label?.text == "accessLevel" else {
          return Optional<TokenSyntax>.none
        }
        return $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName ?? "private"
      }.first ?? "private"

    return [
      "\(userDefinedAccessLevel) let \(raw: ObservationLockableMacro.prefixed)\(label): Mutex<\(property.type!.trimmed)>"
    ]
  }
}

public struct ObservationLockableIgnoredMacro: PeerMacro, Sendable {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    return []
  }
}
