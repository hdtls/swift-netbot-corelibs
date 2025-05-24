//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import SwiftUI

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct ConnectionSearchResults: View {

    typealias Element = Connection

    @Binding private var selectedConnectionID: Element.ID?
    @Environment(RecentConnectionsControler.self) private var connections
    @State private var sortOrder: [KeyPathComparator<Element>] = [.init(\.taskIdentifier)]

    private var searchResult: [Element] {
      if let options {
        return connections.search(tokens: [options])
      }
      return connections.search(tokens: [])
    }
    private let options: ConnectionFilter?

    init(_ options: Binding<ConnectionFilter?>, selection: Binding<Element.ID?>) {
      self._selectedConnectionID = selection
      self.options = options.wrappedValue
    }

    var body: some View {
      #if os(iOS)
        List(searchResult, selection: $selectedConnectionID) { connection in
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
          of: Element.self, selection: $selectedConnectionID, sortOrder: $sortOrder
        ) {
          TableColumn("") { connection in
            ConnectionState(connection.state)
              .font(.system(size: 11))
          }
          .width(12)
          TableColumn("ID", value: \.taskIdentifier.description)
          TableColumn("Date") {
            Text($0.earliestBeginDate, format: .dateTime.hour().minute().second())
          }
          TableColumn("Client") { connection in
            Label {
              Text(
                connection.processReport.processIdentifier == nil
                  ? "\(connection.processReport.processName ?? "Unknown")"
                  : "\(connection.processReport.processName ?? "Unknown") (\(String(connection.processReport.processIdentifier!)))"
              )
            } icon: {
              connection.processReport.processIcon.frame(width: 18, height: 18)
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
          Group {
            TableColumn("Up") { (conn: Element) in
              Text(
                Int64(
                  clamping: conn.dataTransferReport.aggregatePathReport
                    .sentApplicationByteCount
                ),
                format: .byteCount(style: .binary, spellsOutZero: false)
              )
            }
            TableColumn("Down") {
              Text(
                Int64(
                  clamping: $0.dataTransferReport.aggregatePathReport
                    .receivedApplicationByteCount),
                format: .byteCount(style: .binary, spellsOutZero: false)
              )
            }
          }
          TableColumn("Duration") {
            Text(
              $0.dataTransferReport.duration,
              format: .units(
                allowed: [.seconds, .milliseconds], width: .narrow, maximumUnitCount: 1)
            )
          }
          TableColumn("Protocol") {
            Text(verbatim: $0.protocol)
          }
          TableColumn("URL") {
            Text($0.currentRequest.url())
          }
        } rows: {
          ForEach(searchResult)
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
    #Preview(traits: .persistentStore()) {
      @Previewable @State var options: ConnectionFilter?
      @Previewable @State var selection: Connection.ID?

      ConnectionSearchResults($options, selection: $selection)
    }
  #endif
#endif
