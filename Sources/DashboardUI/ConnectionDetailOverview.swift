//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import SwiftUI

  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  extension ConnectionDetail {

    struct Overview: View {

      typealias Data = Connection

      private let data: Data

      init(_ data: Data) {
        self.data = data
      }

      #if os(iOS)
        var body: some View {
          Section {
            HStack {
              Text("URL")
              Spacer()
              Text(data.currentRequest.host(percentEncoded: false) ?? "")
                .foregroundStyle(.secondary)
            }
            HStack {
              Text("Date")
              Spacer()
              Text(data.earliestBeginDate.formatted(date: .long, time: .standard))
                .foregroundStyle(.secondary)
            }
            HStack {
              Text("Status")
              Spacer()
              Text(data.state.localizedName)
                .foregroundStyle(.secondary)
            }
            HStack {
              Text("Duration")
              Spacer()
              Text(
                data.dataTransferReport.duration,
                format: .units(
                  allowed: [.seconds, .milliseconds], width: .narrow, maximumUnitCount: 1)
              )
              .foregroundStyle(.secondary)
            }
          }

          Section {
            HStack {
              Text("Policy")
              Spacer()
              //            Text(data.policy)
              //              .foregroundStyle(.secondary)
            }
            HStack {
              Text("forwardingRule")
              Spacer()
              Text(data.forwardingReport.source ?? "")
                .foregroundStyle(.secondary)
            }
          }

          Section("IP Address") {
            HStack {
              Text("Local IP Address")
              Spacer()
              //            Text(data.addressReport.localIPAddress)
              //              .foregroundStyle(.secondary)
            }
            HStack {
              Text("Remote IP Address")
              Spacer()
              //            Text(data.addressReport.remoteIPAddress)
              //              .foregroundStyle(.secondary)
            }
            HStack {
              Text("Remote IP Region")
              Spacer()
              //            Text(data.addressReport.remoteIPAddressRegion)
              //              .foregroundStyle(.secondary)
            }
            HStack {
              Text("Remote IP ASN")
              Spacer()
              //            Text(data.addressReport.remoteIPAddressASN)
              //              .foregroundStyle(.secondary)
            }

            HStack {
              Text("Remote IP ASO")
              Spacer()
              //            Text(data.addressReport.remoteIPAddressASO)
              //              .multilineTextAlignment(.trailing)
              //              .foregroundStyle(.secondary)
            }
          }

          Section("Speed") {
            HStack {
              Text("Max Download Speed")
              Spacer()
              //            Text(
              //              data.dataTransferReport.receivedTransportBandwidth,
              //              format: .byteCount(style: .binary, spellsOutZero: false)
              //            )
              //            .foregroundStyle(.secondary)
            }

            HStack {
              Text("Max Upload Speed")
              Spacer()
              //            Text(
              //              data.dataTransferReport.sentTransportBandwidth,
              //              format: .byteCount(style: .binary, spellsOutZero: false)
              //            )
              //            .foregroundStyle(.secondary)
            }
          }

          Section("Notes") {
            Text("N/A")
              .font(.footnote)
          }
        }
      #else
        var body: some View {
          HStack(alignment: .top) {
            Grid {
              GridRow {
                GroupBox("HTTP") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Method:")
                      Text(data.currentRequest.httpRequest?.method.rawValue ?? "N/A")
                    }
                    GridRow {
                      Text("Status Code:")
                      if let status = data.response?.httpResponse?.status {
                        Text(verbatim: "\(status.code) \(status.reasonPhrase)")
                      } else {
                        Text(verbatim: "N/A")
                      }
                    }
                  }
                  .frame(width: 145, alignment: .leading)
                }

                GroupBox("Max Bandwidth") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Upload:")
                      //                      Text(
                      //                        data.dataTransferReport.sentTransportBandwidth,
                      //                        format: .byteCount(style: .binary))
                    }
                    GridRow {
                      Text("Download:")
                      //                      Text(
                      //                        data.dataTransferReport.receivedTransportBandwidth,
                      //                        format: .byteCount(style: .binary))
                    }
                  }
                  .frame(width: 145, alignment: .leading)
                }

                GroupBox("Policy") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Rule:")
                      Text(data.forwardingReport.prettyPrintedRule)
                        .lineLimit(1)
                    }
                    GridRow {
                      Text("Policy:")
                      Text(data.forwardingReport.protocol)
                        .lineLimit(1)
                    }
                  }
                  .frame(width: 220, alignment: .leading)
                }
              }

              GridRow {
                GroupBox("Total Traffic") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Upload:")
                      Text(
                        Int64(
                          truncatingIfNeeded: data.dataTransferReport.aggregatePathReport
                            .sentApplicationByteCount),
                        format: .byteCount(style: .binary)
                      )
                    }
                    GridRow {
                      Text("Download:")
                      Text(
                        Int64(
                          truncatingIfNeeded: data.dataTransferReport.aggregatePathReport
                            .receivedApplicationByteCount),
                        format: .byteCount(style: .binary))
                    }
                  }
                  .frame(width: 145, alignment: .leading)
                }

                GroupBox("Current Speed") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Upload:")
                      //                      Text(
                      //                        "\(Text(data.dataTransferReport.sentTransportByteCountPerSecond, format: .byteCount(style: .binary)))/s"
                      //                      )
                    }
                    GridRow {
                      Text("Download:")
                      //                      Text(
                      //                        "\(Text(data.dataTransferReport.receivedTransportByteCountPerSecond, format: .byteCount(style: .binary)))/s"
                      //                      )
                    }
                  }
                  .frame(width: 145, alignment: .leading)
                }

                GroupBox("IP Address") {
                  Grid(alignment: .leading) {
                    GridRow {
                      Text("Local Address:")
                      Text(
                        "\(data.establishmentReport.sourceEndpoint ?? .hostPort(host: .name("N/A"), port: 0))"
                          .replacing(/:[0-9]+/, with: ""))
                    }
                    GridRow {
                      Text("Remote Address:")
                      Text(
                        "\(data.establishmentReport.destinationEndpoint ?? .hostPort(host: .name("N/A"), port: 0))"
                          .replacing(/:[0-9]+/, with: ""))
                    }
                  }
                  .frame(width: 220, alignment: .leading)
                }
              }
            }

            GroupBox("Misc") {
              Grid(alignment: .topLeading) {
                GridRow {
                  Text("Hostname:")
                  Text(data.currentRequest.host(percentEncoded: false) ?? "")
                }
                GridRow {
                  Text("Start Time:")
                  Text(
                    (data.earliestBeginDate).formatted(
                      date: .abbreviated, time: .standard))
                }
              }
              .frame(maxWidth: 275, alignment: .leading)
              .frame(maxHeight: .infinity, alignment: .top)
            }

            Spacer(minLength: 0)
          }
          .frame(maxWidth: .infinity)
          .fixedSize(horizontal: false, vertical: true)
          .font(.footnote)
        }
      #endif
    }
  }

  #if DEBUG
    @available(iOS 17.0, macOS 14.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable var data = Connection(
        originalRequest: .init(address: .hostPort(host: "swift.org", port: .https)))

      #if os(iOS)
        List {
          ConnectionDetail.Overview(data)
        }
      #elseif os(macOS)
        ConnectionDetail.Overview(data)
          .frame(width: 800)
      #endif
    }
  #endif
#endif
