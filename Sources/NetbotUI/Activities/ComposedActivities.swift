//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import Netbot
  import SwiftUI

  struct ComposedActivities: View {
    enum Activity: String, CaseIterable, Hashable, Identifiable {
      case latency
      case traffic
      case interfaces

      var id: Self {
        return self
      }
    }

    @State private var activity: Activity = .latency
    @State private var timeScope: StatisticsTimeScope = .today
    #if DEBUG
      @State private var events: [EventLog] = EventLog.generateAll()
    #else
      @State private var events: [EventLog] = []
    #endif
    @AppStorage(Prefs.Name.enableSystemProxy) private var enableSystemProxy = false

    #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
      @AppStorage(Prefs.Name.enableEnhancedMode) private var enableEnhancedMode = false
    #endif

    private let monitor = WLANManager()
    private let locationManager = LocationManager()

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text("Activity")
          .font(.largeTitle)
          .bold()

        HStack {
          Picker(selection: $activity) {
            ForEach(Activity.allCases) {
              Text($0.rawValue.capitalized)
            }
          }
          .pickerStyle(.segmented)
          .fixedSize()

          Spacer()

          switch activity {
          case .latency:
            Button("Diagnostics") {

            }

            Button("Test Latency") {

            }
          case .traffic:
            Picker(selection: $timeScope) {
              Section {
                Text(StatisticsTimeScope.today.localizedName)
                  .tag(StatisticsTimeScope.today)
                Text(StatisticsTimeScope.sinceLaunch.localizedName)
                  .tag(StatisticsTimeScope.sinceLaunch)
              }
              Section {
                Text(StatisticsTimeScope.latest5Minutes.localizedName)
                  .tag(StatisticsTimeScope.latest5Minutes)
                Text(StatisticsTimeScope.latest15Minutes.localizedName)
                  .tag(StatisticsTimeScope.latest15Minutes)
                Text(StatisticsTimeScope.latest60Minutes.localizedName)
                  .tag(StatisticsTimeScope.latest60Minutes)
              }
              Section {
                Text(StatisticsTimeScope.latest6Hours.localizedName)
                  .tag(StatisticsTimeScope.latest6Hours)
                Text(StatisticsTimeScope.latest12Hours.localizedName)
                  .tag(StatisticsTimeScope.latest12Hours)
                Text(StatisticsTimeScope.latest24Hours.localizedName)
                  .tag(StatisticsTimeScope.latest24Hours)
              }
            }
            .fixedSize()
          case .interfaces:
            EmptyView()
          }
        }

        switch activity {
        case .latency:
          NetworkLatencyActivity()
        case .traffic:
          NetworkTrafficActivity(timeScope: timeScope)
        case .interfaces:
          NetworkInterfaceActivity(monitor: monitor, locationManager: locationManager)
        }

        Divider()

        NetworkActivity()
          .padding(.bottom)

        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            Text("Network History")
              .font(.headline)
            Text("Realtime Network Activity")
              .frame(maxWidth: .infinity)
          }
          .frame(maxWidth: .infinity)

          VStack(alignment: .leading) {
            Text("Events")
              .font(.headline)
            ScrollView {
              EventLogStack(events: events)
            }
          }
          .frame(maxWidth: .infinity)
        }

        HStack {
          Spacer()

          Button {
            enableSystemProxy.toggle()
          } label: {
            Label {
              Text("System Proxy")
            } icon: {
              Circle()
                .frame(width: 6, height: 6)
                .offset(y: 1)
                .foregroundColor(enableSystemProxy ? .green : .gray)
            }
          }

          #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
            Button {
              enableEnhancedMode.toggle()
            } label: {
              Label {
                Text("Enhenced Mode")
              } icon: {
                Circle()
                  .frame(width: 6, height: 6)
                  .offset(y: 1)
                  .foregroundColor(enableEnhancedMode ? .green : .gray)
              }
            }
          #endif
        }
      }
      .padding()
      .navigationTitle("Activity")
    }
  }

  #if DEBUG
    #Preview {
      ComposedActivities()
    }
  #endif
#endif
