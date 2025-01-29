//
// See LICENSE.txt for license information
//

#if DEBUG
  import Netbot
  import SwiftData
  import SwiftUI

  enum DataFillAction {
    case fulfill
    case profileOnly
    case custom(_ action: @MainActor (ModelContainer) throws -> Void)
  }

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
