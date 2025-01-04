//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct ProcessDetail: View {
    let report: ProcessStatistics

    var body: some View {
      List {
        HStack {
          Image(nsImage: report.icon)
          Text(report.localizedName)
          Spacer()
        }
        .listRowSeparator(.hidden)

        Section {
          Grid(alignment: .leading) {
            GridRow {
              Text("upload")
              Text("download")
            }
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            GridRow {
              Text(report.bandwidth.sending.formattedSpeedString())
              Text(report.bandwidth.receiving.formattedSpeedString())
            }
            .bold()
          }
          .listRowSeparator(.hidden)
        } header: {
          VStack(alignment: .leading) {
            Text("Bandwidth")
              .font(.subheadline)
              .textCase(.uppercase)
              .foregroundColor(.purple)
            Divider()
          }
        }

        Section {
          Grid(alignment: .leading) {
            GridRow {
              Text("active")
              Text("total since launch")
            }
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            GridRow {
              Text("0")
              Text("211")
            }
            .bold()
          }
          .listRowSeparator(.hidden)
        } header: {
          VStack(alignment: .leading) {
            Text("Connections")
              .font(.subheadline)
              .textCase(.uppercase)
              .foregroundColor(.red)
            Divider()
          }
        }

        Section {
          Group {
            HStack {
              Text("PID")
                .layoutPriority(1)
              Spacer()
              Text("753")
            }

            HStack {
              Text("Top Host")
                .layoutPriority(1)
              Spacer()
              Text("example.com")
            }
          }
          .font(.footnote)
          .listRowSeparator(.hidden)
        } header: {
          VStack(alignment: .leading) {
            Text("Details")
              .font(.subheadline)
              .textCase(.uppercase)
              .foregroundColor(.blue)
            Divider()
          }
        }

        Section {
          Group {
            HStack {
              Text("Today")
                .font(.footnote)
                .layoutPriority(1)
              Spacer()

              Text("/")
                .font(.footnote)
            }
          }
          .font(.footnote)
          .listRowSeparator(.hidden)
        } header: {
          VStack(alignment: .leading) {
            Text("Traffic")
              .font(.subheadline)
              .textCase(.uppercase)
              .foregroundColor(.orange)
            Divider()
          }
        }
      }
      .listStyle(.inset)
      .scrollContentBackground(.hidden)
      .cornerRadius(10)
    }
  }

  #if DEBUG
    #Preview {
      ProcessDetail(report: .init())
    }
  #endif
#endif
