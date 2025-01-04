//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  public import SwiftUI

  public struct ProcessCell: View {
    private var process: ProcessStatistics

    public init(process: ProcessStatistics) {
      self.process = process
    }

    public var body: some View {
      HStack {
        Label {
          Text(process.localizedName)
        } icon: {
          Image(nsImage: process.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
        }

        Spacer()
        Text(process.bandwidth.receiving.formattedSpeedString())
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .cornerRadius(6)
    }
  }

  public struct ProcessesPage: View {
    public enum SortOptions: CaseIterable, Hashable {
      case traffic
      case speed
      case name

      public var localizedName: String {
        switch self {
        case .traffic:
          return String(localized: "Sort by Traffic")
        case .speed:
          return String(localized: "Sort by Speed")
        case .name:
          return String(localized: "Sort by Name")
        }
      }
    }

    @Environment(\.processes) private var contentData
    @State private var sortOptions: SortOptions = .traffic
    @State private var turnOnMeteredNetworkMode = false
    @State private var selection: ProcessStatistics?

    public var body: some View {
      VStack(alignment: .leading) {
        HStack {
          Text("Process")
            .font(.largeTitle)
            .bold()

          Spacer()

          Picker("", selection: $sortOptions) {
            ForEach(SortOptions.allCases, id: \.self) { options in
              Text(options.localizedName)
            }
          }
          .pickerStyle(.menu)
          .labelsHidden()
          .frame(width: 180)
        }
        .padding(.bottom)

        HStack {
          VStack(alignment: .leading) {
            List(contentData.processes, id: \.self, selection: $selection) {
              ProcessCell(process: $0)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .overlay {
              if contentData.processes.isEmpty {
                ContentUnavailableView {
                  Text("No Processes")
                    .font(.body)
                }
              }
            }

            Divider()
              .padding(.bottom, 8)

            HStack {
              Toggle("Metered Network Mode", isOn: $turnOnMeteredNetworkMode)
                .toggleStyle(.switch)

              Spacer()

              Button {

              } label: {
                Image(systemName: "gearshape")
              }
              .buttonStyle(.plain)
            }

            Text(
              "After enabled, all processes will be blocked to access internet by default. Useful when using a metered connection like mobile data hotspot."
            )
            .font(.footnote)
            .foregroundColor(.secondary)
          }

          ZStack {
            if let process = selection {
              ProcessDetail(report: process)
            } else {
              ContentUnavailableView {
                Text("No Selection")
                  .font(.body)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .overlay {
                RoundedRectangle(cornerRadius: 10)
                  .stroke(Color.gray.opacity(0.3), style: .init(dash: [3], dashPhase: 3))
              }
            }
          }
        }
      }
      .padding()
      .navigationTitle("Process")
    }
  }

  #if DEBUG
    #Preview {
      ProcessesPage()
        .environment(ProcessesStore())
    }
  #endif
#endif
