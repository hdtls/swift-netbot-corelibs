//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import Logging
  import SwiftUI

  struct EventLog: Hashable {
    var level: Logger.Level
    var date: Date
    var message: String
  }

  struct EventLogStack: View {
    let events: [EventLog]

    var body: some View {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(events, id: \.self) { eventLog in
          VStack(alignment: .leading) {
            HStack {
              Text("•\(eventLog.level.rawValue)")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(textColor(for: eventLog.level))
              Text(eventLog.date, style: .date)
                .font(.footnote)
                .foregroundColor(.secondary)
              Text(eventLog.date, style: .time)
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            Text(eventLog.message)
              .font(.footnote)
          }
        }
      }
    }

    private func textColor(for level: Logger.Level) -> Color {
      switch level {
      case .info:
        return .green
      case .warning:
        return .yellow
      case .error:
        return .red
      default:
        return .gray
      }
    }
  }

  #if DEBUG
    #Preview {
      EventLogStack(events: EventLog.generateAll())
    }
  #endif
#endif
