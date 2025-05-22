//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import SwiftUI
  import _PersistentStore

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct RecentConnections: View {

    typealias Data = RecentConnectionsControler

    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities = CapabilityFlags()

    @State private var height = CGFloat.zero
    @State private var controlSize = CGSize.zero
    @State var selection: Connection.ID?

    private let data: Data

    init(_ data: Data) {
      self.data = data
    }

    var body: some View {
      GeometryReader { geometry in
        VStack(spacing: 0) {
          ConnectionSearchResults(data.searchResult, selection: $selection)

          VStack(spacing: 0) {
            Divider()
            HStack {
              Button("Clear") {
                Task {
                  await data.erase()
                }
              }

              Button("Reload") {
                Task {
                  await data.update()
                }
              }

              Button {
                if enabledHTTPCapabilities.contains(.httpCapture) {
                  enabledHTTPCapabilities.remove(.httpCapture)
                } else {
                  enabledHTTPCapabilities.insert(.httpCapture)
                }
              } label: {
                if enabledHTTPCapabilities.contains(.httpCapture) {
                  Text("Disable HTTP Capture")
                } else {
                  Text("Enable HTTP Capture")
                }
              }

              Button {
                if enabledHTTPCapabilities.contains(.httpsDecryption) {
                  enabledHTTPCapabilities.remove(.httpsDecryption)
                } else {
                  enabledHTTPCapabilities.insert(.httpsDecryption)
                }
              } label: {
                if enabledHTTPCapabilities.contains(.httpsDecryption) {
                  Text("Disable MitM")
                } else {
                  Text("Enable MitM")
                }
              }

              Spacer()

              Button {
                openDetails(at: height >= _openDetails ? 0 : _openDetails)
              } label: {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
                  Image(systemName: "inset.filled.bottomthird.square")
                } else {
                  Image(systemName: "square.bottomthird.inset.filled")
                }
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            Divider()
          }
          .background {
            GeometryReader { g in
              self.controlSize = g.size
              return Color.clear
                #if os(macOS)
                  .onHover { isHovered in
                    if isHovered {
                      if #available(macOS 15.0, *) {
                        NSCursor.rowResize(directions: .all).push()
                      } else {
                        NSCursor.resizeUpDown.push()
                      }
                    } else {
                      NSCursor.pop()
                    }
                  }
                #endif
                .gesture(
                  DragGesture()
                    .onChanged { value in
                      let h = height - value.translation.height

                      if h <= 100 {
                        openDetails(at: 0)
                      } else if h <= _openDetails {
                        openDetails()
                      } else if h >= geometry.size.height - g.size.height - 100 {
                        openDetails(at: geometry.size.height - g.size.height)
                      } else if h >= geometry.size.height - g.size.height - 200 {
                        openDetails(at: geometry.size.height - g.size.height - 200)
                      } else {
                        openDetails(at: h)
                      }
                    }
                )
            }
          }

          if let connection = data.searchResult.first(where: { $0.taskIdentifier == selection }) {
            ConnectionDetail(connection)
              .padding(.horizontal)
              .padding(.vertical, 8)
              .frame(height: height, alignment: .top)
          } else {
            Color.clear.frame(height: height)
          }
        }
        .onChange(of: selection) { _, n in
          if let n {
            openDetails(at: height >= _openDetails ? height : _openDetails)
          } else {
            openDetails(at: 0)
          }
        }
      }
    }

    private let _openDetails: CGFloat = 225
    private func openDetails(at size: CGFloat = 225) {
      height = size
      if size == 0 {
        selection = nil
      }
    }
  }

  #if DEBUG
    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable let data = RecentConnectionsControler(modelContainer: .makeSharedContext())

      RecentConnections(data)
    }
  #endif
#endif
