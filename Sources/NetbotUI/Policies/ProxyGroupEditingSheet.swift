//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

#if os(macOS)
  struct ProxyGroupEditingSheet: View {

    @AppStorage(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL = URL.profile

    @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    private var selectionRecordForGroups = SelectionRecordForGroups()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.profileAssistant) private var profileAssistant
    @Environment(\.session) private var session

    @State private var step: EditingStep = .selectType
    @State private var isLoading = false
    @State private var progress: Progress = .init()
    @State private var data: AnyProxyGroup

    private let persistentModel: AnyProxyGroup.PersistentModel?
    private var titleKey: LocalizedStringKey {
      persistentModel == nil ? "New Proxy Group" : "Edit Proxy Group"
    }

    init(data: AnyProxyGroup.PersistentModel?) {
      self.persistentModel = data
      if let data {
        self._data = State(initialValue: .init(persistentModel: data))
      } else {
        self._data = State(initialValue: .init())
      }
    }

    var body: some View {
      NavigationStack {
        ProxyGroupEditor(data: $data, step: $step)
          .padding()
          .navigationTitle(titleKey)
          .toolbar {
            toolbarItems
          }
      }
    }

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
      ToolbarItem {
        Button("Cancel", role: .cancel) {
          withAnimation {
            dismiss()
          }
        }
      }

      ToolbarItem {
        Spacer()
      }

      ToolbarItem(placement: .cancellationAction) {
        if step.canGoBack {
          Button("Previous") {
            step.goBack()
          }
        }
      }

      ToolbarItem(placement: .confirmationAction) {
        if case .editName = step {
          Button("Done") {
            withAnimation {
              save()
              dismiss()
            }
          }
          .disabled(data.name.isEmpty)
        } else {
          Button("Next") {
            step.goForward()
          }
          .disabled(step == .selectPolicies && data.lazyProxies.isEmpty)
        }
      }
    }

    private var externalPoliciesFileURL: URL? {
      get async throws {
        guard let url = data.resource.externalProxiesURL, !url.isFileURL else {
          return data.resource.externalProxiesURL
        }

        isLoading = true
        defer { isLoading = false }
        return nil
        //        let destination: DownloadRequest.Destination = { temporaryURL, response in
        //          (temporaryURL, [])
        //        }
        //        let request = session.download(url, to: destination)
        //        Task {
        //          for await progress in request.downloadProgress() {
        //            Task { @MainActor in
        //              // We now have a progress.
        //              self.progress = progress
        //            }
        //          }
        //        }
        //        return try await request.serializingDownloadedFileURL().value
      }
    }

    func save() {
      Task { @MainActor in
        var fd = FetchDescriptor<Profile.PersistentModel>()
        fd.predicate = #Predicate { $0.url == profileURL }
        fd.sortBy = [.init(\.creationDate)]
        guard let profile = try modelContext.fetch(fd).first else {
          return
        }

        var lazyProxies: [AnyProxy.PersistentModel] = []
        if let url = try await externalPoliciesFileURL {
          lazyProxies = try String(contentsOf: url, encoding: .utf8).split(
            separator: .newlineSequence
          ).map {
            var parseOutput = try AnyProxy.FormatStyle().parse(String($0))
            parseOutput.source = .externalResource
            parseOutput.name = "\(data.name)_\(parseOutput.name)"
            let proxy = AnyProxy.PersistentModel()
            proxy.mergeValues(parseOutput)
            return proxy
          }
        } else {
          lazyProxies = profile.lazyProxies.filter({ data.lazyProxies.contains($0.name) })
        }

        var persistentModel = self.persistentModel

        if let persistentModel {
          // Remove policies if needed.
          if persistentModel.resource.externalProxiesURL != nil {
            let prefix = "\(persistentModel.name)_"
            try modelContext.delete(
              model: AnyProxy.PersistentModel.self,
              where: #Predicate {
                $0.lazyProfile?.url == profileURL && $0.name.starts(with: prefix)
              })
          }

          Task(priority: .background) {
            try await profileAssistant.replace(.init(persistentModel: persistentModel), with: data)
          }
          selectionRecordForGroups.replaceKey(persistentModel.name, with: data.name)

          // Update selection if policy is removed from policy group.
          let term = selectionRecordForGroups[persistentModel.name]
          let hasBeenRemoved = !persistentModel.lazyProxies.contains(where: { $0.name == term })
          if hasBeenRemoved {
            selectionRecordForGroups.removeKey(persistentModel.name)
          }
        } else {
          persistentModel = AnyProxyGroup.PersistentModel()
          profile.lazyProxyGroups.append(persistentModel.unsafelyUnwrapped)
          modelContext.insert(persistentModel.unsafelyUnwrapped)
          Task(priority: .background) {
            try await profileAssistant.insert(data)
          }
        }

        if let persistentModel {
          persistentModel.mergeValues(data)
          persistentModel.lazyProxies = lazyProxies
        }
        try modelContext.save()
      }
    }
  }
#endif

extension ProxyGroupEditingSheet {
  enum EditingStep {
    case selectType
    case selectPolicies
    case editName

    var canGoBack: Bool {
      self != .selectType
    }

    var canGoForward: Bool {
      self != .editName
    }

    mutating func goForward() {
      switch self {
      case .selectType:
        self = .selectPolicies
      case .selectPolicies:
        self = .editName
      case .editName:
        break
      }
    }

    mutating func goBack() {
      switch self {
      case .selectType:
        break
      case .selectPolicies:
        self = .selectType
      case .editName:
        self = .selectPolicies
      }
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit Proxy Group", traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxyGroup.PersistentModel]
    ProxyGroupEditingSheet(data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New Proxy Group", traits: .persistentStore()) {
    ProxyGroupEditingSheet(data: nil)
  }
#endif
