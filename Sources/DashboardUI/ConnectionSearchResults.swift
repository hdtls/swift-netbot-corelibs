//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Dashboard
  import SwiftUI

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct ConnectionSearchResults: View {

    @Binding private var selection: Connection?

    #if os(macOS)
      @State private var selectedConnectionID: Connection.ID?
    #endif
    @State private var sortOrder: [KeyPathComparator<Connection>] = []

    typealias Data = [Connection]
    private let data: Data

    init(_ data: Data, selection: Binding<Connection?>) {
      self.data = data
      self._selection = selection
    }

    var body: some View {
      #if os(iOS)
        List(data, selection: $selection) { connection in
          NavigationLink(value: connection) {
            VStack(alignment: .leading, spacing: 4) {
              if let host = connection.currentRequest.host(percentEncoded: false),
                let port = connection.currentRequest.port
              {
                Text("\(host):\(port)")
              }
              //            Text(
              //              "#\(connection.id) - \(connection.startDate) - \(connection.policy) - \(connection.dataTransferReport.receivedTransportByteCountPerSecond) - \(connection.state.localizedName)"
              //            )
              //            .lineLimit(1)
              //            .foregroundColor(Color.secondary)
              //            .font(.footnote)
            }
          }
        }
        .navigationTitle("Recent Requests")
      #elseif os(macOS)
        Table(
          of: Connection.self, selection: $selectedConnectionID, sortOrder: $sortOrder
        ) {
          TableColumn("") { connection in
            ConnectionState(connection.state)
              .font(.system(size: 11))
          }
          .width(12)
          TableColumn("ID", value: \.taskIdentifier.description)
          TableColumn("Date") {
            Text($0.earliestBeginDate, format: .dateTime.hour().minute().second()).equatable()
          }
          TableColumn("Client") { connection in
            Label {
              Text(
                connection.processReport.processIdentifier == nil
                  ? "\(connection.processReport.processName ?? "Unknown")"
                  : "\(connection.processReport.processName ?? "Unknown") (\(connection.processReport.processIdentifier!))"
              )
            } icon: {
              connection.processReport.processIcon
                .frame(width: 18, height: 18)
            }
          }
          TableColumn("Status", value: \.state.localizedName)
          TableColumn("Policy") {
            Text(
              verbatim: $0.forwardingReport.prettyPrintedRule == "N/A"
                ? $0.forwardingReport.protocol
                : "\($0.forwardingReport.protocol) (\($0.forwardingReport.prettyPrintedRule))"
            )
          }
          TableColumn("Up") {
            Text(
              Int64(
                truncatingIfNeeded: $0.dataTransferReport.aggregatePathReport.sentTransportByteCount
              ),
              format: .byteCount(style: .binary, spellsOutZero: false)
            )
          }
          TableColumn("Down") {
            Text(
              Int64(
                truncatingIfNeeded: $0.dataTransferReport.aggregatePathReport
                  .receivedTransportByteCount),
              format: .byteCount(style: .binary, spellsOutZero: false)
            )
          }
          TableColumn("Duration") {
            Text(
              $0.dataTransferReport.duration,
              format: .units(
                allowed: [.seconds, .milliseconds], width: .narrow, maximumUnitCount: 1)
            )
          }
          //        TableColumn("Protocol", value: \.`protocol`)
          TableColumn("URL") {
            Text($0.currentRequest.url())
          }
        } rows: {
          ForEach(data)
        }
        .onChange(of: selectedConnectionID) {
          selection = data.first(where: { $0.taskIdentifier == selectedConnectionID })
        }
      #else
        EmptyView()
      #endif
    }
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable let data: [Connection] = []
      @Previewable @State var selection: Connection?

      ConnectionSearchResults(data, selection: $selection)
    }
  #endif
#endif
