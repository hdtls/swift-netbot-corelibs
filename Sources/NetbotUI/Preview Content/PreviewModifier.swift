//
// See LICENSE.txt for license information
//

#if DEBUG
  import Netbot
  import SwiftData
  import SwiftUI
  import SwiftUIPreview

  enum DataFillAction {
    case fulfill
    case profileOnly
    case custom(_ action: @MainActor (ModelContainer) throws -> Void)
  }

  struct PersistentStorePreviewable<Data>: View where Data: PersistentModel {

    @Query private var models: [Data]

    private var content: ([Data]) -> AnyView
    private var dataFillAction: DataFillAction
    private let context: ModelContainer

    init(
      dataFillAction: DataFillAction = .fulfill,
      @ViewBuilder content: @escaping ([Data]) -> some View
    ) {
      self.context = try! .preview
      self.dataFillAction = .fulfill
      self.content = { models in content(models).eraseToAnyView() }
    }

    init(dataFillAction: DataFillAction = .fulfill, @ViewBuilder content: @escaping () -> some View)
    where Data == Profile.PersistentModel {
      self.context = try! .preview
      self.dataFillAction = .fulfill
      self.content = { _ in content().eraseToAnyView() }
    }

    var body: some View {
      PersistentModelContainerPreview {
        content(models)
      } modelContainer: {
        context
      }
      .task {
        do {
          switch dataFillAction {
          case .fulfill:
            let profile = Profile.PersistentModel.preview
            context.mainContext.insert(profile)
            let lazyProxies = try profile.generateLazyProxies()
            let lazyProxyGroups = try profile.generateLazyProxyGroups(lazyProxies: lazyProxies)
            try profile.generateLazyRules(
              lazyProxies: lazyProxies, lazyProxyGroups: lazyProxyGroups)
            try profile.generateLazyDNSMappings()
            try profile.generateLazyURLRewrites()
            try profile.generateLazyHTTPResponseMocks()
            try profile.generateLazyHTTPFieldsRewrites()
          case .profileOnly:
            let profile = Profile.PersistentModel.preview
            context.mainContext.insert(profile)
          case .custom(let action):
            try action(context)
          }
        } catch {}
      }
    }
  }

  typealias BindingPreviewable = SwiftUIPreview.BindingPreviewable

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  struct SwiftDataPreviewModifier: PreviewModifier {

    var dataFillAction: DataFillAction = .fulfill

    static func makeSharedContext() throws -> ModelContainer {
      try .preview
    }

    func body(content: Content, context: ModelContainer) -> some View {
      content.modelContainer(context)
        .task {
          do {
            switch dataFillAction {
            case .fulfill:
              let profile = Profile.PersistentModel.preview
              context.mainContext.insert(profile)
              let lazyProxies = try profile.generateLazyProxies()
              let lazyProxyGroups = try profile.generateLazyProxyGroups(lazyProxies: lazyProxies)
              try profile.generateLazyRules(
                lazyProxies: lazyProxies, lazyProxyGroups: lazyProxyGroups)
              try profile.generateLazyDNSMappings()
              try profile.generateLazyURLRewrites()
              try profile.generateLazyHTTPResponseMocks()
              try profile.generateLazyHTTPFieldsRewrites()
            case .profileOnly:
              let profile = Profile.PersistentModel.preview
              context.mainContext.insert(profile)
            case .custom(let action):
              try action(context)
            }
          } catch {}
        }
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  extension PreviewTrait where T == Preview.ViewTraits {

    @MainActor static func persistentStore(dataFillAction: DataFillAction = .fulfill) -> Self {
      .modifier(SwiftDataPreviewModifier(dataFillAction: dataFillAction))
    }
  }
#endif
