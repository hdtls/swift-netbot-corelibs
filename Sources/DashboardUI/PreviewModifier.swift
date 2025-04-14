//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  #if DEBUG
    import AnlzrReports
    import Dashboard
    import SwiftData
    import SwiftUI

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    extension ModelContainer {
      static func makeSharedContext() -> ModelContainer {
        let schema = Schema(versionedSchema: V1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
      }
    }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    enum DataFillAction {
      case fulfill
      case profileOnly
      case custom(_ action: @MainActor (ModelContainer) throws -> Void)
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    struct SwiftDataPreviewModifier: PreviewModifier {

      var dataFillAction: DataFillAction = .fulfill

      static func makeSharedContext() throws -> ModelContainer {
        ModelContainer.makeSharedContext()
      }

      func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
          .task {
            do {
              switch dataFillAction {
              case .fulfill:
                try context.mainContext.transaction {
                  //              for persistentModel in Connection.generateAll() {
                  //                context.mainContext.insert(persistentModel)
                  //              }
                }
              case .profileOnly:
                try context.mainContext.transaction {
                  //              for persistentModel in Connection.generateAll() {
                  //                context.mainContext.insert(persistentModel)
                  //              }
                }
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
#endif
