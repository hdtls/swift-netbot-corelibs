//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EditableMacro: MemberMacro, Sendable {

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let attributes = declaration.attributes.compactMap {
      if case .attribute(let attribute) = $0 {
        let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)
        return attributeName?.name.text == "Editable" ? attribute : nil
      }
      return nil
    }

    guard let attribute = attributes.first else {
      return []
    }

    var data: TokenSyntax?

    if let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self) {
      data =
        attributeName.genericArgumentClause?.arguments.first?.argument.as(
          IdentifierTypeSyntax.self)?.name
    }

    if data == nil {
      let argument = attribute.arguments?.as(LabeledExprListSyntax.self)?.first {
        $0.label?.text == "data"
      }

      let expression = argument?.expression.as(MemberAccessExprSyntax.self)
      data = expression?.base?.as(DeclReferenceExprSyntax.self)?.baseName
    }

    guard let data else {
      return []
    }

    var declarations: [DeclSyntax] = []

    let properties = declaration.memberBlock.members
      .lazy.compactMap {
        $0.decl.as(VariableDeclSyntax.self)
      }
      .flatMap { $0.bindings }
      .compactMap { $0.pattern.as(IdentifierPatternSyntax.self) }
      .compactMap { $0.identifier.text }

    if !properties.contains("profileURL") {
      declarations.append(
        "@AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile"
      )
    }

    if !properties.contains("dismiss") {
      declarations.append("@Environment(\\.dismiss) private var dismiss")
    }

    if !properties.contains("modelContext") {
      declarations.append("@Environment(\\.modelContext) private var modelContext")
    }

    if !properties.contains("profileAssistant") {
      declarations.append("@Environment(\\.profileAssistant) private var profileAssistant")
    }

    if !properties.contains("data") {
      declarations.append("@State private var data: \(data)")
    }

    if !properties.contains("persistentModel") {
      declarations.append("private let persistentModel: \(data).PersistentModel?")
    }

    let initializers = declaration.memberBlock.members.compactMap {
      $0.decl.as(InitializerDeclSyntax.self)
    }

    if initializers.count <= 1 {
      if let initializer = initializers.first {
        let parameters = initializer.signature.parameterClause.parameters
        if parameters.count == 1 && parameters.first?.firstName.text == "_data" {
          declarations.append(
            """
            init(data: \(data).PersistentModel?) {
              self.persistentModel = data
              if let data {
                self._data = .init(initialValue: .init(persistentModel: data))
              } else {
                self._data = .init(initialValue: .init())
              }
            }
            """)
        }
      } else {
        declarations.append(
          """
          init(data: \(data).PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
          """)
      }
    }

    let functions = declaration.memberBlock.members.compactMap {
      $0.decl.as(FunctionDeclSyntax.self)
    }

    if !functions.contains(where: { $0.name.text == "save" }) {
      declarations.append(
        """
        private func save() {
          do {
            if let persistentModel {
              let outdated = \(data)(persistentModel: persistentModel)
              persistentModel.mergeValues(data)
              Task(priority: .background) {
                try await profileAssistant.replace(outdated, with: data)
              }
            } else {
              var fd = FetchDescriptor<Profile.PersistentModel>()
              fd.predicate = #Predicate {  $0.url == profileURL }
              guard let profile = try modelContext.fetch(fd).first else {
                return
              }
              Task(priority: .background) {
                try await profileAssistant.insert(data)
              }
              let persistentModel = \(data).PersistentModel()
              persistentModel.mergeValues(data)
              persistentModel.lazyProfile = profile
            }

            try modelContext.save()
          } catch {
            assertionFailure(error.localizedDescription)
          }
        }
        """)
    }
    return declarations
  }
}
