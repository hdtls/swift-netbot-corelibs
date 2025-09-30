//
// See LICENSE.txt for license information
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(EditableMacros)
  import EditableMacros

  let testMacros: [String: (Macro & Sendable).Type] = [
    "Editable": EditableMacro.self
  ]
#endif

@Suite struct EditableMacrosTests {

  #if canImport(EditableMacros)
    @Test func editableMacro() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
          macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
          indentationWidth: .spaces(2)
        ) {
          #expect(
            Bool(false),
            "\($0.message)",
            sourceLocation: SourceLocation(
              fileID: $0.location.fileID,
              filePath: $0.location.filePath,
              line: $0.location.line,
              column: $0.location.column
            )
          )
        }
      }
    }

    @Test func ignoreProfileURLProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile
        }
        """
      let expectedExpandedSource = """
        struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreDismissProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.dismiss) private var dismiss
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.dismiss) private var dismiss

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreModelContextProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.modelContext) private var modelContext
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.modelContext) private var modelContext

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreProfileAssistantProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.profileAssistant) private var profileAssistant
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @Environment(\\.profileAssistant) private var profileAssistant

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreDataProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          @State private var data: Data
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          @State private var data: Data

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignorePersistentModelProperty() throws {
      let originalSource =
        """
        @Editable<Data> struct Presentation {

          private let persistentModel: Data.PersistentModel?
        }
        """

      let expectedExpandedSource = """
        struct Presentation {

          private let persistentModel: Data.PersistentModel?

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreInitialzier() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreInitializerIfAlreadyContainsMoreThanOneInititlaizers() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreInitializerIfExisitInitializerIsNotBuildForPreview() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func generateInitializerIfExistInitializerIsForPreview() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }

    @Test func ignoreSaveFunction() throws {
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

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

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
        macroSpecs: testMacros.mapValues { MacroSpec(type: $0) },
        indentationWidth: .spaces(2)
      ) {
        #expect(
          Bool(false),
          "\($0.message)",
          sourceLocation: SourceLocation(
            fileID: $0.location.fileID,
            filePath: $0.location.filePath,
            line: $0.location.line,
            column: $0.location.column
          )
        )
      }
    }
  #endif
}
