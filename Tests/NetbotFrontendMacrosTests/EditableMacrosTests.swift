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

#if canImport(NetbotFrontendMacros)
  import NetbotFrontendMacros
  import Testing

  @Suite(.tags(.swiftmacros))
  struct EditableMacrosTests {

    @Test(arguments: [
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
    ])
    func editableMacro(originalSource: String) throws {
      assertMacroExpansion(
        originalSource,
        expandedSource: """
          struct Presentation {

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreProfileURLProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile
        }
        """,
        expandedSource: """
          struct Presentation {

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreDismissProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.dismiss) private var dismiss
        }
        """,
        expandedSource: """
          struct Presentation {

            @Environment(\\.dismiss) private var dismiss

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreModelContextProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.modelContext) private var modelContext
        }
        """,
        expandedSource: """
          struct Presentation {

            @Environment(\\.modelContext) private var modelContext

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreProfileAssistantProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          @Environment(\\.profileAssistant) private var profileAssistant
        }
        """,
        expandedSource: """
          struct Presentation {

            @Environment(\\.profileAssistant) private var profileAssistant

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreDataProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          @State private var data: Data
        }
        """,
        expandedSource: """
          struct Presentation {

            @State private var data: Data

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignorePersistentModelProperty() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          private let persistentModel: Data.Model?
        }
        """,
        expandedSource: """
          struct Presentation {

            private let persistentModel: Data.Model?

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreInitialzier() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          init(data: Data.Model?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """,
        expandedSource: """
          struct Presentation {

            init(data: Data.Model?) {
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

            private let persistentModel: Data.Model?

            private func save() {
              do {
                if let persistentModel {
                  let outdated = Data(persistentModel: persistentModel)
                  persistentModel.mergeValues(data)
                  Task(priority: .background) {
                    try await profileAssistant.replace(outdated, with: data)
                  }
                } else {
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreInitializerIfAlreadyContainsMoreThanOneInititlaizers() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          init(data: Data.Model?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }

          init() {}
        }
        """,
        expandedSource: """
          struct Presentation {

            init(data: Data.Model?) {
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

            private let persistentModel: Data.Model?

            private func save() {
              do {
                if let persistentModel {
                  let outdated = Data(persistentModel: persistentModel)
                  persistentModel.mergeValues(data)
                  Task(priority: .background) {
                    try await profileAssistant.replace(outdated, with: data)
                  }
                } else {
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreInitializerIfExisitInitializerIsNotBuildForPreview() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          init(data: Data.Model?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """,
        expandedSource: """
          struct Presentation {

            init(data: Data.Model?) {
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

            private let persistentModel: Data.Model?

            private func save() {
              do {
                if let persistentModel {
                  let outdated = Data(persistentModel: persistentModel)
                  persistentModel.mergeValues(data)
                  Task(priority: .background) {
                    try await profileAssistant.replace(outdated, with: data)
                  }
                } else {
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func generateInitializerIfExistInitializerIsForPreview() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          init(_data: Data.Model?) {
            self.persistentModel = data
            if let data {
              self._data = .init(initialValue: .init(persistentModel: data))
            } else {
              self._data = .init(initialValue: .init())
            }
          }
        }
        """,
        expandedSource: """
          struct Presentation {

            init(_data: Data.Model?) {
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

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
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
                  var fd = FetchDescriptor<Profile.Model>()
                  fd.predicate = #Predicate {
                    $0.url == profileURL
                  }
                  guard let profile = try modelContext.fetch(fd).first else {
                    return
                  }
                  Task(priority: .background) {
                    try await profileAssistant.insert(data)
                  }
                  let persistentModel = Data.Model()
                  persistentModel.mergeValues(data)
                  persistentModel.lazyProfile = profile
                }

                try modelContext.save()
              } catch {
                assertionFailure(error.localizedDescription)
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }

    @Test func ignoreSaveFunction() throws {
      assertMacroExpansion(
        """
        @Editable<Data> struct Presentation {

          private func save() {
          }
        }
        """,
        expandedSource: """
          struct Presentation {

            private func save() {
            }

            @AppStorage(Prefs.Name.profileURL, store: .__shared) private var profileURL = URL.profile

            @Environment(\\.dismiss) private var dismiss

            @Environment(\\.modelContext) private var modelContext

            @Environment(\\.profileAssistant) private var profileAssistant

            @State private var data: Data

            private let persistentModel: Data.Model?

            init(data: Data.Model?) {
              self.persistentModel = data
              if let data {
                self._data = .init(initialValue: .init(persistentModel: data))
              } else {
                self._data = .init(initialValue: .init())
              }
            }
          }
          """,
        macros: ["Editable": EditableMacro.self]
      )
    }
  }
#endif
