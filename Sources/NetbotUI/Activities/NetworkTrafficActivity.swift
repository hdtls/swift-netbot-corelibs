//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import Netbot
  import SwiftData
  import SwiftUI

  enum StatisticsTimeScope: Hashable {
    case today
    case sinceLaunch
    case latest5Minutes
    case latest15Minutes
    case latest60Minutes
    case latest6Hours
    case latest12Hours
    case latest24Hours

    var localizedName: LocalizedStringKey {
      switch self {
      case .today:
        return "Today"
      case .sinceLaunch:
        return "Since Launch"
      case .latest5Minutes:
        return "Latest 5 Minutes"
      case .latest15Minutes:
        return "Latest 15 Minutes"
      case .latest60Minutes:
        return "Latest 60 Minutes"
      case .latest6Hours:
        return "Latest 6 Hours"
      case .latest12Hours:
        return "Latest 12 Hours"
      case .latest24Hours:
        return "Latest 24 Hours"
      }
    }
  }

  struct NetworkTrafficActivity: View {
    typealias Data = AnyProxy.PersistentModel

    @Environment(\.modelContext) private var modelContext
    @Query private var searchResults: [Data]
    @State private var proxy: AnyProxy.PersistentModel?
    private let timeScope: StatisticsTimeScope

    init(timeScope: StatisticsTimeScope = .today) {
      let term = AnyProxy.Source.userDefined.rawValue
      self._searchResults = Query(filter: #Predicate { $0.source == term }, sort: \.creationDate)
      self.timeScope = timeScope
    }

    var body: some View {
      HStack {
        GroupBox {
          VStack(alignment: .leading) {
            Label("Total", systemImage: "arrow.up.arrow.down")
              .font(.headline)
              .foregroundColor(.blue)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("2.06")
                .font(.title)
                .bold()
              Text("GB")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(width: 150, alignment: .leading)
        }

        GroupBox {
          VStack(alignment: .leading) {
            Label("Direct", systemImage: "arrow.left.and.right")
              .font(.headline)
              .foregroundColor(.green)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("2.06")
                .font(.title)
                .bold()
              Text("GB")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(width: 150, alignment: .leading)
        }

        GroupBox {
          VStack(alignment: .leading) {
            Label {
              Text(proxy?.name ?? " ")
                .lineLimit(1)
                .truncationMode(.tail)
            } icon: {
              Image(systemName: "arrow.triangle.branch")
                .rotationEffect(Angle(degrees: 90))
            }
            .font(.headline)
            .foregroundColor(.orange)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
              Text("2")
                .font(.title)
                .bold()
              Text("KB")
                .bold()
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(width: 150, alignment: .leading)
          .overlay(alignment: .topTrailing) {
            Menu("...") {
              ForEach(searchResults) { model in
                Toggle(
                  model.name,
                  isOn: .init(
                    get: { model.persistentModelID == proxy?.persistentModelID },
                    set: { proxy = $0 ? model : proxy }
                  )
                )
              }
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
            .padding(.trailing, 8)
          }
        }
      }
    }
  }

  #if DEBUG
    #Preview {
      PersistentStorePreviewable {
        NetworkTrafficActivity()
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      NetworkTrafficActivity()
    }
  #endif
#endif
