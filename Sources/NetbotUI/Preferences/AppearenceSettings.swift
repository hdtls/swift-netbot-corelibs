//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct AppearenceSettings: View {

  #if os(macOS)
    @AppStorage(Prefs.Name.menuBarExtraTitleLabelStyle)
    private var menuBarExtraTitleLabelStyle = _MenuBarExtra.LabelStyle.titleAndIcon

    @AppStorage(Prefs.Name.showMainWindowAfterLaunching)
    private var showMainWindowAfterLaunching = true
  #endif

  #if EXTENDED_ALL
    @AppStorage(Prefs.Name.showNetworkConnectivityQualilty)
    private var showConnectivityQuality = true

    @AppStorage(Prefs.Name.showRemoteDashboardShortcuts)
    private var showRemoteDashboardShortcuts = false

    @AppStorage(Prefs.Name.dockDisplayMode)
    private var dockDisplayMode = DockDisplayMode.followTheMainWindow

    @AppStorage(Prefs.Name.isLocalNotificationsEnabled)
    private var isLocalNotificationsEnabled = true

    @AppStorage(Prefs.Name.shouldAutomaticallyDismissInessentialNotifications)
    private var shouldAutomaticallyDismissInessentialNotifications = false

    @AppStorage(Prefs.Name.isCloudNotificationsEnabled)
    private var isCloudNotificationsEnabled = true
  #endif

  @AppStorage(Prefs.Name.maximumNumberOfProcesses)
  private var maximumNumberOfProcesses = 10

  @AppStorage(Prefs.Name.shouldGrayOutStatusBarItem)
  private var shouldGrayOutStatusBarItem = true

  @AppStorage(Prefs.Name.shouldCollapsePolicyGroupIfThereAreMoreThanFiveItems)
  private var shouldCollapsePolicyGroupIfThereAreMoreThanFiveItems = false

  var body: some View {
    Form {
      #if os(macOS)
        Section {
          LabeledContent("Menu Bar Item:") {
            VStack(alignment: .leading) {
              Picker(selection: $menuBarExtraTitleLabelStyle) {
                ForEach(_MenuBarExtra.LabelStyle.allCases, id: \.self) {
                  Text($0.localizedName)
                }
              }
              .labelsHidden()
              Toggle(
                "Gray out when neither Set as System Proxy or Enhanced Mode is enabled",
                isOn: $shouldGrayOutStatusBarItem
              )
            }
          }
        }

        Section {
          LabeledContent("Menu Bar Item Menu:") {
            VStack(alignment: .leading) {
              #if EXTENDED_ALL
                Toggle(
                  "Show connectivity quality (DNS round-trip time)",
                  isOn: $showConnectivityQuality
                )
              #endif

              Toggle(
                "Collapse policy group items",
                isOn: $shouldCollapsePolicyGroupIfThereAreMoreThanFiveItems
              )

              #if EXTENDED_ALL
                Toggle(
                  "Show remote dashboard shortcuts",
                  isOn: $showRemoteDashboardShortcuts
                )
              #endif

              HStack {
                Text("Show up to")
                TextField(
                  "",
                  value: $maximumNumberOfProcesses,
                  format: .number
                )
                .labelsHidden()
                .frame(width: 20)
                .onChange(of: maximumNumberOfProcesses) {
                  maximumNumberOfProcesses = max(0, min(10, maximumNumberOfProcesses))
                }
                Stepper("", value: $maximumNumberOfProcesses, in: 0...10)
                  .labelsHidden()
                Text("top processes")
              }
            }
          }
        }

        #if EXTENDED_ALL
          Section {
            Picker("Show Dock:", selection: $dockDisplayMode) {
              ForEach(DockDisplayMode.allCases, id: \.self) {
                Text($0.localizedName)
              }
            }
          }
        #endif

        Section {
          LabeledContent("Main Windown:") {
            Toggle("Show main window after launching", isOn: $showMainWindowAfterLaunching)
          }
        }
      #endif
      #if EXTENDED_ALL
        Section {
          LabeledContent("Notifications:") {
            VStack(alignment: .leading) {
              Toggle("Enable local notifications", isOn: $isLocalNotificationsEnabled)
              Button("Choose Allowed Local Notifications") {

              }
              Toggle(
                "Automatically dismiss inessential notifications after a few seconds",
                isOn: $shouldAutomaticallyDismissInessentialNotifications
              )
              Toggle("Enable cloud notifications", isOn: $isCloudNotificationsEnabled)
              Text(
                "You can receive the notifications on iOS devices. Enable this option first and then configure it on \(ProcessInfo.processInfo.processName) iOS. The two device must use a same iCloud account."
              )
              .foregroundStyle(.secondary)
              .font(.footnote)
              .frame(width: 450)
              .fixedSize()
              Button("Choose Allowed Cloud Notifications") {

              }
            }
          }
        }
      #endif
    }
    .navigationTitle("Appearence")
    #if os(macOS)
      .padding()
      .fixedSize()
    #endif
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      AppearenceSettings()
    }
  }
#endif
