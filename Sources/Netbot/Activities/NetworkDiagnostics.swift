//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Dispatch
  import Foundation
  import Logging
  import Network
  import Observation

  @available(SwiftStdlib 5.9, *)
  @MainActor @Observable public class NetworkDiagnostics {

    private class SessionDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

      weak var assistant: NetworkDiagnostics?

      init(assistant: NetworkDiagnostics) {
        self.assistant = assistant
      }

      func urlSession(
        _ session: URLSession, task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
      ) {
        Task { @MainActor in
          guard let assistant, let transactionMetrics = metrics.transactionMetrics.first else {
            return
          }
          if let domainLookupEndDate = transactionMetrics.domainLookupEndDate,
            let domainLookupStartDate = transactionMetrics.domainLookupStartDate
          {
            assistant.dnsLatency =
              Duration
              .seconds(domainLookupStartDate.distance(to: domainLookupEndDate))
              .formatted(assistant.formatStyle)
          }
          if let requestStartDate = transactionMetrics.requestStartDate,
            let responseStartDate = transactionMetrics.responseStartDate
          {
            assistant.internetLatency =
              Duration
              .seconds(requestStartDate.distance(to: responseStartDate))
              .formatted(assistant.formatStyle)
          }
        }
      }
    }
    
    /// DNS latency in ms.
    public var dnsLatency = "N/Ams"

    /// Router latency in ms.
    public var routerLatency = "N/Ams"

    /// Internet latency in ms.
    public var internetLatency = "N/Ams"

    public let coreWLAN = WLANManager()

    private let defaultTimeout: TimeInterval = 3.0
    private let formatStyle = Duration.UnitsFormatStyle.units(
      allowed: [.milliseconds],
      width: .narrow,
      maximumUnitCount: 1
    )
    private let logger = Logger(label: "com.tenbits.coreWLAN.diagnostics")

    @ObservationIgnored private lazy var sessionDelegate = SessionDelegate(assistant: self)

    nonisolated public init() {
    }

    /// Measure Internet latency by fetching a tiny known endpoint (Apple's connectivity check) with a HEAD request.
    private func measureInternetLatency() {
      let url = URL(string: "https://captive.apple.com/hotspot-detect.html")!
      var urlRequest = URLRequest(url: url)
      urlRequest.httpMethod = "HEAD"
      urlRequest.timeoutInterval = defaultTimeout

      let configuration = URLSessionConfiguration.default
      configuration.proxyConfigurations = []
      configuration.connectionProxyDictionary = [:]

      let session = URLSession(
        configuration: configuration,
        delegate: sessionDelegate,
        delegateQueue: OperationQueue()
      )
      session.dataTask(with: urlRequest).resume()
    }

    /// Measure TCP connect time to port 53.
    private func measureRouterLatency() {
      guard let routerIPString = coreWLAN.networkService.v4.router,
        let router = IPv4Address(routerIPString)
      else {
        return
      }
      let connection = NWConnection(to: .hostPort(host: .ipv4(router), port: 53), using: .tcp)
      let startTime = Date.now
      connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
          Task { @MainActor [weak self] in
            guard let self else { return }
            routerLatency = Duration.seconds(startTime.distance(to: .now)).formatted(formatStyle)
          }
        case .failed:
          connection.cancel()
        default: break
        }
      }
      connection.start(queue: .global())
    }

    /// Measure latency for Router, DNS and Internet.
    public func testLatency() {
      // Router latency test require router address.
      // To make router latency test available we try
      // to get router address as possible as we can.
      var retryAttampts = 3
      while retryAttampts > 0 {
        coreWLAN.getWLANInfo()
        if coreWLAN.networkService.v4.router != nil {
          break
        }
        retryAttampts -= 1
      }

      logger.trace(
        """
        Primary IPv4 interface: \(coreWLAN.interfaceName)
        Primary IPv4 Address: \(coreWLAN.networkService.v4.addresses.first ?? "N/A")
        Default IPv4 Router: \(coreWLAN.networkService.v4.router ?? "N/A")
        Primary IPv6 Address: \(coreWLAN.networkService.v6.addresses.first ?? "N/A")
        Default IPv6 Router: \(coreWLAN.networkService.v6.router ?? "N/A")
        Effective DNS Servers: \(coreWLAN.networkService.dnsServers.joined(separator: ","))
        """)
      measureInternetLatency()
      measureRouterLatency()
    }
  }
#endif
