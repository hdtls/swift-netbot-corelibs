//
// See LICENSE.txt for license information
//

#if DEBUG
  #if os(macOS) && EXTENDED_ALL
    import Foundation
    import Logging

    private let logger = Logger(label: "Data Generation")

    extension EventLog {

      static func generateAll() -> [EventLog] {
        logger.info("Generating all event log...")
        let all: [EventLog] = [
          .init(
            level: .info,
            date: Date(),
            message: "SOCKS5 proxy listen on interface: 0.0.0.0, port: 6153"
          ),
          .init(
            level: .info,
            date: Date(),
            message: "HTTP proxy listen on interface: 0.0.0.0, port: 6152"
          ),
          .init(
            level: .error,
            date: Date(),
            message:
              "Proxy 🇯🇵 VMESS encountered a fatal error: DNS lookup failed: Socket closed by remote peer"
          ),
        ]
        logger.info("Completed generating all of the event log.")
        return all
      }
    }
  #endif
#endif
