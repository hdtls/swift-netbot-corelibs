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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct LockableMacro: Sendable {
  static let prefixed = "_"
  static let lockable = "Lockable"
  static let lockableTracked = "LockableTracked"
  static let lockableIgnored = "LockableIgnored"
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct Lockable {

  enum Accessor: String, Comparable, Hashable {
    static func < (lhs: Lockable.Accessor, rhs: Lockable.Accessor) -> Bool {
      lhs.rawValue < rhs.rawValue
    }

    case get
    case set
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LockableMacro: MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol, in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self), property.isLockable else {
      return []
    }

    if property.hasMacro(named: LockableMacro.lockableTracked)
      || property.hasMacro(named: LockableMacro.lockableIgnored)
    {
      return []
    }

    return [
      AttributeSyntax(
        attributeName: IdentifierTypeSyntax(name: .identifier(LockableMacro.lockableTracked)),
        leftParen: node.arguments != nil ? .leftParenToken() : nil,
        arguments: node.arguments,
        rightParen: node.arguments != nil ? .rightParenToken() : nil
      )
    ]
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct LockableTrackedMacro: AccessorMacro, Sendable {
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

    guard !property.hasMacro(named: LockableMacro.lockableIgnored) else {
      return []
    }

    var accessors: [Lockable.Accessor]

    if var arguments = node.arguments?.as(LabeledExprListSyntax.self) {
      if let firstIndex = arguments.firstIndex(where: { $0.label?.text == "accessors" }) {
        arguments.removeSubrange(arguments.startIndex..<firstIndex)
        accessors =
          arguments
          .compactMap { $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text }
          .compactMap { Lockable.Accessor(rawValue: $0) }
      } else {
        accessors = [.get, .set]
      }
    } else {
      accessors = [.get, .set]
    }

    accessors = Set(accessors).sorted()
    if accessors.contains(.set) && !accessors.contains(.get) {
      throw MacroExpansionErrorMessage("Variable with a setter must also have a getter")
    }
    return accessors.map {
      switch $0 {
      case .get:
        let accessor: AccessorDeclSyntax = """
          get {
            self.\(raw: LockableMacro.prefixed)\(label).withLock {
              $0
            }
          }
          """
        return accessor
      case .set:
        let accessor: AccessorDeclSyntax = """
          set {
            self.\(raw: LockableMacro.prefixed)\(label).withLock {
              $0 = newValue
            }
          }
          """
        return accessor
      }
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LockableTrackedMacro: PeerMacro {
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

    if property.hasMacro(named: LockableMacro.lockableIgnored) {
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
      "\(userDefinedAccessLevel) let \(raw: LockableMacro.prefixed)\(label): Mutex<\(property.type!.trimmed)>"
    ]
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct LockableIgnoredMacro: PeerMacro, Sendable {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    return []
  }
}
