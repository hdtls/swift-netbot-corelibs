//
// See LICENSE.txt for license information
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(NetbotMacros)
  import NetbotMacros

  let testMacros: [String: Macro.Type] = [
    "Editable": EditableMacro.self
  ]
#endif

final class EditableMacrosTests: XCTestCase {

  func testEditableMacro() throws {
    #if canImport(NetbotMacros)
      let originalSources = [
        """
        @Editable<Data> struct Presentation {
        }
        """,
        """
        @Editable<Data>(data: Data.self) struct Presentation {
        }
        """,
        """
        @Editable(data: Data.self) struct Presentation {
        }
        """,
      ]
      let expectedExpandedSource = """
        struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      for originalSource in originalSources {
        assertMacroExpansion(
          originalSource,
          expandedSource: expectedExpandedSource,
          macros: testMacros,
          indentationWidth: .spaces(2)
        )
      }
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreProfileURLProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile
        }
        """
      let expectedExpandedSource = """
        struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreDismissProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.dismiss) private var dismiss
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.dismiss) private var dismiss

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreModelContextProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.modelContext) private var modelContext
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.modelContext) private var modelContext

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreProfileAssistantProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.profileAssistant) private var profileAssistant
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.profileAssistant) private var profileAssistant

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreDataProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @State private var data: Data
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @State private var data: Data

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnorePersistentModelProperty() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          private let persistentModel: Data.PersistentModel?
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          private let persistentModel: Data.PersistentModel?

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreInitialzier() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreInitializerIfAlreadyContainsMoreThanOneInititlaizers() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          init() {}
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          init() {}

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreInitializerIfExisitInitializerIsNotBuildForPreview() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testGenerateInitializerIfExistInitializerIsForPreview() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          init(_data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          init(_data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          private func save() {
            do {
              if let persistentModel {
                let outdated = Data(persistentModel: persistentModel)
                persistentModel.mergeValues(data)
                Task(priority: .background) {
                  try await profileAssistant.replace(outdated, with: data)
                }
              } else {
                var fd = FetchDescriptor<Profile.PersistentModel>()
                fd.predicate = #Predicate {
                  $0.url == profileURL
                }
                guard let profile = try modelContext.fetch(fd).first else {
                  return
                }
                Task(priority: .background) {
                  try await profileAssistant.insert(data)
                }
                let persistentModel = Data.PersistentModel()
                persistentModel.mergeValues(data)
                persistentModel.lazyProfile = profile
              }

              try modelContext.save()
            } catch {
              assertionFailure(error.localizedDescription)
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testIgnoreSaveFunction() {
    #if canImport(NetbotMacros)
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          private func save() {
          }
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          private func save() {
          }

          @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

          @Environment(\\.dismiss) private var dismiss

          @Environment(\\.modelContext) private var modelContext

          @Environment(\\.profileAssistant) private var profileAssistant

          @State private var data: Data

          private let persistentModel: Data.PersistentModel?

          init(data: Data.PersistentModel?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """
      assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        macros: testMacros,
        indentationWidth: .spaces(2)
      )
    #else
      throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
