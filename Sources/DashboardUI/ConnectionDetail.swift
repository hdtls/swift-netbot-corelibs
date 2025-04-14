//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import _PersistentStore
  import SwiftUI
  import NEAddressProcessing

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct ConnectionDetail: View {
    private enum SegmentedPickerTag: String, CaseIterable {
      case overview = "Overview"
      #if os(iOS)
        case timing = "Timing"
        case request = "Request"
        case response = "Response"
      #else
        case timingAndNotes = "Timing & Notes"
        case requestHead = "Request Head"
        case requestBody = "Request Body"
        case responseHead = "Response Head"
        case responseBody = "Response Body"
      #endif
    }

    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities: CapabilityFlags = []

    @State private var segmented: SegmentedPickerTag = .overview

    typealias Data = Connection

    private let data: Data

    init(_ data: Data) {
      self.data = data
    }

    #if os(iOS)
      var body: some View {
        List {
          Picker(selection: $segmented) {
            ForEach(SegmentedPickerTag.allCases, id: \.self) {
              Text($0.rawValue).tag($0)
            }
          } label: {
          }
          .pickerStyle(.segmented)
          .listRowBackground(Color.clear)

          switch segmented {
          case .overview:
            Overview(data)
          case .timing:
            EmptyView()
          case .request:
            EmptyView()
          case .response:
            EmptyView()
          }
        }
        .navigationTitle("Request Detail")
      }
    #elseif os(macOS)
      var body: some View {
        VStack(alignment: .leading) {
          HStack {
            data.processReport.processIcon
              .frame(width: 29, height: 29)

            VStack(alignment: .leading, spacing: 4) {
              Text(data.processReport.processName ?? "Unknown")
                .font(.title)
                .bold()

              Text(verbatim: data.currentRequest.url())
            }
          }
          .frame(alignment: .leading)

          Picker("", selection: $segmented) {
            ForEach(SegmentedPickerTag.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .fixedSize()

          switch segmented {
          case .overview:
            Overview(data)
          case .timingAndNotes:
            GroupBox {
              TextEditor(
                text: .constant(
                  """
                  Rule Evaluating - 2 ms
                  Establishing Connection - 22 ms
                  Active - 59 s

                  Events
                  18:47:13.441719 Waiting previous evaluating context
                  18:47:13.443302 Rule evaluating requires DNS lookup for Rule: RULE-SET LAN
                  18:47:13.443692 Rule matched: GEOIP CN
                  18:47:13.447046 Use the last successful address: 121.14.76.58
                  18:47:13.447249 Connecting with address: 121.14.76.58
                  18:47:13.467322 Connected to address 121.14.76.58 in 19ms
                  18:47:13.467708 TCP connection established
                  18:48:13.350803 Disconnect with reason: Closed by client
                  """
                )
              )
              .textEditorStyle(.plain)
            }
          case .requestHead:
            GroupBox {
              TextEditor(text: .constant(data.currentRequest.formatted()))
                .textEditorStyle(.plain)
            }
          case .requestBody:
            GroupBox {
              TextEditor(
                text: .constant(
                  enabledHTTPCapabilities.contains(.httpCapture)
                    ? "\(data.currentRequest.formatted(strategy: .body))"
                    : "Turn on HTTP capture and configure MitM to dump and inspect the body.")
              )
              .textEditorStyle(.plain)
            }
          case .responseHead:
            GroupBox {
              TextEditor(text: .constant(data.response?.formatted() ?? ""))
                .textEditorStyle(.plain)
            }
          case .responseBody:
            GroupBox {
              TextEditor(
                text: .constant(
                  enabledHTTPCapabilities.contains(.httpCapture)
                    ? "\(data.response?.formatted(strategy: .body) ?? "No Data")"
                    : "Turn on HTTP capture and configure MitM to dump and inspect the body.")
              )
              .textEditorStyle(.plain)
            }
          }
        }
      }
    #else
      var body: some View {
        EmptyView()
      }
    #endif
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable var data = Connection(
        originalRequest: .init(address: .hostPort(host: "swift.org", port: .https)))

      #if os(iOS)
        ConnectionDetail(data)
      #elseif os(macOS)
        ConnectionDetail(data)
          .frame(width: 800)
      #endif
    }
  #endif
#endif
