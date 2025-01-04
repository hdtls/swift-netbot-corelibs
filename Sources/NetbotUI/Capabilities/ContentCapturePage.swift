//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ContentCapturePage: View {
  @AppStorage(Prefs.Name.hideRequestsThatBelongToApple, store: .applicationGroup)
  private var hideRequestsThatBelongToApple = false

  @AppStorage(Prefs.Name.hideRequestsThatBelongToCrashReporters, store: .applicationGroup)
  private var hideRequestsThatBelongToCrashReporters = false

  @AppStorage(Prefs.Name.hideUDPConversations, store: .applicationGroup)
  private var hideUDPConversations = false

  @AppStorage(Prefs.Name.combineSystemProcesses, store: .applicationGroup)
  private var combineSystemProcesses = false

  @Environment(\.openURL) private var openURL
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var contentStorageURL: URL?
  @State private var textToAdd = ""

  // TODO: Request Filter
  @State private var strategy: RequestFilterStrategy = .noFilter
  @State private var requestFilterValues: [String] = []

  var body: some View {
    VStack(alignment: .leading) {
      CapabilitiesToggle(option: .httpCapture) {
        Text("Capture HTTP Content")
          .font(.largeTitle)
          .bold()
      }
      .toggleStyle(.switch)

      Text(
        "Turning on the switch to capture all HTTP traffic. This will significantly impact the performance and may drain disk space. Only enable when necessary. HTTPS traffic can also be dumped if MitM is enabled."
      )
      .font(.footnote)
      .foregroundColor(.secondary)
      .padding(.bottom)

      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          Section {
            Toggle("Hide Apple Requests", isOn: $hideRequestsThatBelongToApple)
            Text(
              "Hide all requests send to *.apple.com and *.icloud.com. Please note that hidden requests will still be affected by outbound mode or other settings."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading)

            Toggle("Hide Crash Reporters Requests", isOn: $hideRequestsThatBelongToCrashReporters)
            Text(
              "Hide the requests of common app crash reporters (Firebase, Bugsnag, Crashlytics and more), since their requests may flood the recent request log."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading)

            Toggle("Hide UDP Conversations", isOn: $hideUDPConversations)

            Toggle("Combine System Processes", isOn: $combineSystemProcesses)
            Text("Combine all system processes into a single item in the process view.")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.leading)
          } header: {
            Text("Visibility")
              .textCase(.uppercase)
              .font(.headline)
              .foregroundColor(.yellow)
            Divider()
          }

          Section {
            Text("Local Path: \(contentStorageURL?.absoluteString ?? "Not Available")")
            Button("Reveal in Finder") {
              if let url = contentStorageURL, url.isFileURL {
                openURL(url)
              }
            }
            .disabled(contentStorageURL == nil)
          } header: {
            Text("Storage")
              .textCase(.uppercase)
              .font(.headline)
              .foregroundColor(.green)
              .padding(.top, 16)
            Divider()
          } footer: {
            Text(
              "Dump files are saved in the temporary directory. The system may delete it at bootup or at regular intervals."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }
        .padding(.trailing)

        VStack(alignment: .leading) {
          // TODO: Request Filter
          Section {
            Picker(selection: $strategy) {
              ForEach(RequestFilterStrategy.allCases, id: \.self) {
                Text($0.abstract).tag($0)
              }
            }
            #if os(macOS)
              .pickerStyle(.radioGroup)
            #endif
            .padding(.bottom)

            Literals($requestFilterValues)
              .title("Keywords")
              .navigationTitle("New Keyword")
          } header: {
            Text("Dashboard Filter")
              .textCase(.uppercase)
              .font(.headline)
              .foregroundColor(.blue)
            Divider()
          }
        }
      }
    }
    .padding()
  }
}

#if DEBUG
  #Preview {
    ContentCapturePage()
  }
#endif
