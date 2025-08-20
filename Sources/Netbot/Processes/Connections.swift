//
// See LICENSE.txt for license information
//

#if os(macOS)
  import AnlzrReports
  import CoreData
  import Dispatch
  import Foundation
  import Logging
  import NEAddressProcessing
  import Network
  import Observation
  import SwiftData
  import NIOConcurrencyHelpers

  public enum LocalizedError: Foundation.LocalizedError, Equatable {
    case nw(NWError)
    case operationUnsupported

    public var errorDescription: String? {
      switch self {
      case .nw(let error):
        switch error {
        case .posix:
          return error.localizedDescription
        case .dns, .tls:
          return error.localizedDescription
        case .wifiAware:
          return error.localizedDescription
        @unknown default:
          return error.localizedDescription
        }
      case .operationUnsupported:
        return "Operation Unsupported"
      }
    }
  }

  public protocol ConnectionsDependency: Sendable {

    var messages: AsyncStream<Result<[Connection], LocalizedError>> { get }

    func run()

    func shutdownGracefully()
  }

  final class DefaultConnectionsDependency: ConnectionsDependency {
    public let messages: AsyncStream<Result<[Connection], LocalizedError>>
    private let continuation: AsyncStream<Result<[Connection], LocalizedError>>.Continuation

    private let connection = NIOLockedValueBox<NWConnection?>(nil)

    private nonisolated let logger = Logger(label: "com.tenbits.netbot.dashboard")

    public init() {
      (messages, continuation) = AsyncStream<Result<[Connection], LocalizedError>>.makeStream()
    }

    public func run() {
      let parameters = NWParameters.tcp
      let options = NWProtocolWebSocket.Options()
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
      let connection = self.connection.withLockedValue {
        $0 = NWConnection(to: .url(URL(string: "ws://127.0.0.1:6170")!), using: parameters)
        return $0!
      }
      connection.stateUpdateHandler = { [weak self] state in
        guard let self else { return }

        switch state {
        case .setup:
          break
        case .waiting(let error):
          logger.error("Fetch connections failure with error: \(error.localizedDescription)")
          continuation.yield(.failure(.nw(error)))
        case .preparing:
          break
        case .ready:
          @Sendable func runReadLoop() {
            guard connection.state == .ready else {
              return
            }

            connection.receiveMessage { [weak self] content, contentContext, isComplete, error in
              guard let data = content, let self else {
                return
              }

              do {
                let models = try JSONDecoder().decode([Connection].self, from: data)
                continuation.yield(.success(models))
              } catch {
                assertionFailure("BUG IN NETBOT CORE, please report: illegal data format \(error)")
                logger.critical("decoding connection failure with error: \(error)")
              }

              runReadLoop()
            }
          }

          runReadLoop()
        case .failed(let error):
          logger.error("Fetch connections failure with error: \(error.localizedDescription)")
          continuation.yield(.failure(.nw(error)))
        case .cancelled:
          break
        @unknown default:
          continuation.yield(.failure(.operationUnsupported))
        }
      }
      connection.start(queue: .global())
    }

    public func shutdownGracefully() {}
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @MainActor @Observable public class Connections {

    nonisolated public static let shared = Connections()

    /// An error encountered during the most recent attempt to fetch data.
    ///
    /// This value is `nil` unless an fetch attempt failed. It contains the
    /// latest error from SwiftData.
    public var fetchError: LocalizedError? {
      self._fetchError
    }
    private var _fetchError: LocalizedError?

    public typealias Result = [Connection]

    public var result: Result {
      self._result
    }
    private var _result: Result = []

    public var processReports: [ProcessReport] {
      self._processReports
    }
    private var _processReports: [ProcessReport] = []

    public var formattedDownloadSpeed: String {
      "\(self._bytesReceived.formatted(.byteCount(style: .binary)))/s"
    }
    private var _bytesReceived = Measurement<UnitInformationStorage>(value: 0, unit: .bytes)

    public var formattedUploadSpeed: String {
      "\(self._bytesSent.formatted(.byteCount(style: .binary)))/s"
    }
    private var _bytesSent = Measurement<UnitInformationStorage>(value: 0, unit: .bytes)

    private nonisolated let logger = Logger(label: "com.tenbits.netbot.dashboard")

    @ObservationIgnored private var connection: NWConnection!

    @ObservationIgnored private var earliestBeginDate = Date.distantPast

    nonisolated private let dependency: any ConnectionsDependency

    nonisolated convenience init() {
      self.init(dependency: DefaultConnectionsDependency())
    }

    nonisolated public init(dependency: some ConnectionsDependency) {
      self.dependency = dependency
    }

    @ObservationIgnored private var timerSource: DispatchSourceTimer!

    public func resume() {
      self._fetchError = nil
      self.dependency.run()

      Task.detached {
        for await message in self.dependency.messages {
          do {
            try await self.insert(message.get())
          } catch {
            self.logger.error("\(error)")
          }
        }
      }

      //      timerSource?.cancel()
      //      timerSource = DispatchSource.makeTimerSource(queue: .main)
      //      timerSource.schedule(deadline: .now(), repeating: .seconds(1))
      //      timerSource.setEventHandler {
      //        var bytesReceived = self._bytesReceived
      //        bytesReceived.value = 0
      //
      //        var bytesSent = self._bytesSent
      //        bytesSent.value = 0
      //
      //        for data in self.result {
      //          for processReport in self.processReports {
      //            if processReport.transactionMetrics.connections.contains(data.taskIdentifier) {
      //              processReport.transactionMetrics.totalBytesReceived.value += Double(
      //                data.dataTransferReport.aggregatePathReport.receivedApplicationByteCount)
      //              processReport.transactionMetrics.totalBytesSent.value += Double(
      //                data.dataTransferReport.aggregatePathReport.sentApplicationByteCount)
      //              processReport.transactionMetrics.bytesReceived.value = Double(
      //                data.dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0)
      //              processReport.transactionMetrics.bytesSent.value = Double(
      //                data.dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0)
      //              processReport.transactionMetrics.countOfActiveConnections +=
      //                data.state == .active ? 1 : 0
      //            }
      //          }
      //
      //          bytesReceived.value += Double(
      //            data.dataTransferReport.aggregatePathReport.receivedApplicationByteCount)
      //          bytesSent.value += Double(
      //            data.dataTransferReport.aggregatePathReport.sentApplicationByteCount)
      //        }
      //
      //        //        for processReport in self._processReports {
      //        //          let metrics = self._result.filter {
      //        //            processReport.transactionMetrics.connections.contains($0.id)
      //        //          }
      //        //          .reduce(into: (Double.zero, Double.zero, Double.zero, Double.zero, 0)) {
      //        //            partialResult, data in
      //        //            partialResult.0 += Double(
      //        //              data.dataTransferReport.aggregatePathReport.receivedApplicationByteCount)
      //        //            partialResult.1 += Double(
      //        //              data.dataTransferReport.aggregatePathReport.sentApplicationByteCount)
      //        //            partialResult.2 += Double(
      //        //              data.dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0)
      //        //            partialResult.3 += Double(
      //        //              data.dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0)
      //        //            partialResult.4 += data.state == .active ? 1 : 0
      //        //          }
      //        //
      //        //          processReport.transactionMetrics.totalBytesReceived.value = metrics.0
      //        //          processReport.transactionMetrics.totalBytesSent.value = metrics.1
      //        //          processReport.transactionMetrics.bytesReceived.value = metrics.2
      //        //          processReport.transactionMetrics.bytesSent.value = metrics.3
      //        //          processReport.transactionMetrics.countOfActiveConnections = metrics.4
      //        //
      //        //          bytesReceived.value += metrics.2
      //        //          bytesSent.value += metrics.3
      //        //        }
      //        //
      //        self._bytesReceived = bytesReceived
      //        self._bytesSent = bytesSent
      //      }
      //      timerSource.resume()
    }

    public func cancel() {
      self._fetchError = nil
      self.dependency.shutdownGracefully()
      self.timerSource?.cancel()
    }

    private func insert(_ models: [Connection]) {
      //      for model in models {
      //        let processReport = self._processReports.first {
      //          $0.processName == model.processReport.processName
      //        }
      //
      //        if let data = self._result.first(where: { $0.taskIdentifier == model.taskIdentifier }) {
      //          data.originalRequest = model.originalRequest
      //          data.currentRequest = model.currentRequest
      //          data.response = model.response
      //          data.earliestBeginDate = model.earliestBeginDate
      //          data.taskDescription = model.taskDescription
      //          data.tls = model.tls
      //          data.state = model.state
      //          data.establishmentReport = model.establishmentReport
      //          data.forwardingReport = model.forwardingReport
      //          data.dataTransferReport = model.dataTransferReport
      //          data.processReport = model.processReport
      //        } else {
      //          if let processReport {
      //            self._result.append(model)
      //
      //            processReport.transactionMetrics.connections.append(model.id)
      //          } else {
      //            self._result.append(model)
      //
      //            let processReport = ProcessReport(
      //              processName: model.processReport.processName,
      //              processBundleURL: model.processReport.processBundleURL,
      //              processExecutableURL: model.processReport.processExecutableURL,
      //              processIconTIFFRepresentation: model.processReport.processIconTIFFRepresentation,
      //              transactionMetrics: .init(
      //                totalBytesReceived: Measurement(
      //                  value: Double(
      //                    model.dataTransferReport.aggregatePathReport.receivedApplicationByteCount),
      //                  unit: .bytes
      //                ),
      //                totalBytesSent: Measurement(
      //                  value: Double(
      //                    model.dataTransferReport.aggregatePathReport.sentApplicationByteCount),
      //                  unit: .bytes
      //                ),
      //                bytesReceived: Measurement(
      //                  value: Double(
      //                    model.dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0),
      //                  unit: .bytes
      //                ),
      //                bytesSent: Measurement(
      //                  value: Double(
      //                    model.dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0),
      //                  unit: .bytes
      //                ),
      //                countOfActiveConnections: model.state == .active ? 1 : 0,
      //                connections: [model.id],
      //                processIdentifiers: model.processReport.processIdentifier != nil
      //                  ? [model.processReport.processIdentifier!] : []
      //              )
      //            )
      //            self._processReports.append(processReport)
      //          }
      //        }
      //      }
    }

    public func erase() {
      self.earliestBeginDate = Date.now
      self._result = []
    }
  }
#endif
