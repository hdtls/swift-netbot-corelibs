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

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @ModelActor private actor RecentConnectionsModelActor {
    typealias Element = Connection.PersistentModel

    /// An error encountered during the most recent attempt to fetch data.
    var fetchError: (any Error)?

    private func query0(filter: Predicate<Element>) -> [Element] {
      do {
        var fd = FetchDescriptor<Element>()
        fd.relationshipKeyPathsForPrefetching = [
          \._originalRequest,
          \._currentRequest,
          \._response,
          \._establishmentReport,
          \._dataTransferReport,
          \._processReport,
        ]
        fd.predicate = filter
        return try modelContext.fetch(fd)
      } catch {
        fetchError = error
        return []
      }
    }

    fileprivate func insert(_ connections: [Connection]) {
      let term = connections.map { $0.taskIdentifier }

      let models = query0(filter: #Predicate { term.contains($0.taskIdentifier) })

      try? modelContext.transaction {
        for connection in connections {
          let existing = models.first(where: { $0.taskIdentifier == connection.taskIdentifier })

          guard existing == nil else {
            existing?.mergeValues(connection)
            existing?._originalRequest?.mergeValues(connection.originalRequest)
            existing?._currentRequest?.mergeValues(connection.currentRequest)
            existing?._establishmentReport?.mergeValues(connection.establishmentReport)
            existing?._processReport?.mergeValues(connection.processReport)
            continue
          }

          let persistentModel = Element()
          persistentModel.mergeValues(connection)

          persistentModel._originalRequest = .init()
          persistentModel._originalRequest?.mergeValues(connection.originalRequest)

          persistentModel._currentRequest = .init()
          persistentModel._currentRequest?.mergeValues(connection.currentRequest)

          persistentModel._establishmentReport = .init()
          persistentModel._establishmentReport?.mergeValues(connection.establishmentReport)

          var fd = FetchDescriptor<AnlzrReports.ProcessReport.PersistentModel>()
          fd.predicate = #Predicate { $0.processName == connection.processReport.processName }

          if let processReport = try modelContext.fetch(fd).first {
            processReport.connections.append(persistentModel)
          } else {
            let processReport = AnlzrReports.ProcessReport.PersistentModel()
            processReport.mergeValues(connection.processReport)
            modelContext.insert(processReport)

            processReport.connections.append(persistentModel)
          }
        }
      }
      try? modelContext.save()
    }

    fileprivate func queryProcessReports() -> [ProcessReport] {
      do {
        var fd = FetchDescriptor<AnlzrReports.ProcessReport.PersistentModel>()
        fd.relationshipKeyPathsForPrefetching = [\.connections]
        let models = try modelContext.fetch(fd)
        return models.map {
          var countOfReceivedBytes = Int64.zero
          var countOfSentBytes = Int64.zero
          var countOfReceivedBytesPerSecond = Int64.zero
          var countOfSentBytesPerSecond = Int64.zero

          for connection in $0.connections {
            guard let dataTransferReport = connection._dataTransferReport else {
              continue
            }
            countOfSentBytes &+= Int64(
              clamping: dataTransferReport.aggregatePathReport.sentApplicationByteCount
            )
            countOfReceivedBytes &+= Int64(
              clamping: dataTransferReport.aggregatePathReport.receivedApplicationByteCount
            )
            countOfSentBytesPerSecond &+= Int64(
              clamping: dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0
            )
            countOfReceivedBytesPerSecond &+= Int64(
              clamping: dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0
            )
          }

          return ProcessReport(
            processName: $0.processName,
            processBundleURL: $0.processBundleURL,
            processExecutableURL: $0.processExecutableURL,
            processIdentifier: $0.processIdentifier,
            processIconTIFFRepresentation: $0.processIconTIFFRepresentation,
            countOfReceivedBytes: countOfReceivedBytes,
            countOfSentBytes: countOfSentBytes,
            countOfReceivedBytesPerSecond: countOfReceivedBytesPerSecond,
            countOfSentBytesPerSecond: countOfSentBytesPerSecond
          )
        }
      } catch {
        fetchError = error
        return []
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @MainActor @Observable public class Connections {

    nonisolated public static let shared = Connections()

    public enum LocalizedError: Foundation.LocalizedError, Equatable {
      case nw(NWError)
      case operationUnsupported

      public var errorDescription: String? {
        switch self {
        case .nw(let error):
          switch error {
          case .posix(let code):
            return error.localizedDescription
          case .dns, .tls:
            return error.localizedDescription
          @unknown default:
            return error.localizedDescription
          }
        case .operationUnsupported:
          return "Operation Unsupported"
        }
      }
    }

    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    public var modelContainer: ModelContainer {
      store.modelContainer
    }

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

    private nonisolated let store: RecentConnectionsModelActor

    private nonisolated let logger = Logger(label: "com.tenbits.netbot.dashboard")

    @ObservationIgnored private var connection: NWConnection!

    @ObservationIgnored private var earliestBeginDate = Date.distantPast

    nonisolated public convenience init() {
      let schema = Schema(versionedSchema: AnlzrReports.V1.self)
      let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      self.init(modelContainer: modelContainer)
    }

    nonisolated public init(modelContainer: ModelContainer) {
      store = RecentConnectionsModelActor(modelContainer: modelContainer)
    }

    public func resume() {
      self._fetchError = nil
      let parameters = NWParameters.tcp
      let options = NWProtocolWebSocket.Options()
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
      connection = NWConnection(to: .url(URL(string: "ws://127.0.0.1:6170")!), using: parameters)
      connection.stateUpdateHandler = { [weak self] state in
        Task { @MainActor in
          guard let self else { return }

          switch state {
          case .setup:
            break
          case .waiting(let error):
            self.logger.error("Fetch connections failure with error: \(error.localizedDescription)")
            self._fetchError = LocalizedError.nw(error)
          case .preparing:
            break
          case .ready:
            self.runReadLoop()
          case .failed(let error):
            self.logger.error("Fetch connections failure with error: \(error.localizedDescription)")
            self._fetchError = LocalizedError.nw(error)
          case .cancelled:
            break
          @unknown default:
            self._fetchError = LocalizedError.operationUnsupported
          }
        }
      }
      connection.start(queue: .global())
    }

    public func cancel() {
      self._fetchError = nil
      if connection != nil {
        connection.cancel()
        self.connection = nil
      }
    }

    private func runReadLoop() {
      guard connection?.state == .ready else {
        return
      }

      connection.receiveMessage { [weak self] content, contentContext, isComplete, error in
        Task.detached {
          guard let data = content, let self else {
            return
          }

          do {
            let models = try JSONDecoder().decode([Connection].self, from: data)
            await self.insert(models)
          } catch {
            assertionFailure("BUG IN NETBOT CORE, please report: illegal data format \(error)")
            self.logger.critical("decoding connection failure with error: \(error)")
          }

          Task { @MainActor in
            self.runReadLoop()
          }
        }
      }
    }

    nonisolated private func insert(_ models: [Connection]) async {
      //      await self.store.insert(models)
      //      Task { @MainActor in
      //        self._processReports = await self.store.queryProcessReports()
      //      }

      for model in models {
        if let data = await self._result.first(
          where: {
            $0.taskIdentifier == model.taskIdentifier
          })
        {
          let dataTransferReport = data.dataTransferReport

          Task { @MainActor in
            data.originalRequest = model.originalRequest
            data.currentRequest = model.currentRequest
            data.response = model.response
            data.earliestBeginDate = model.earliestBeginDate
            data.taskDescription = model.taskDescription
            data.tls = model.tls
            data.state = model.state
            data.establishmentReport = model.establishmentReport
            data.forwardingReport = model.forwardingReport
            data.dataTransferReport = model.dataTransferReport
            data.processReport = model.processReport
          }

          let index = await self._processReports.firstIndex {
            $0.processName == model.processReport.processName
          }

          guard let index else { continue }

          var processReport = await self._processReports[index]
          processReport.countOfReceivedBytes -= Int64(
            clamping: dataTransferReport.aggregatePathReport.receivedApplicationByteCount)
          processReport.countOfReceivedBytes &+= Int64(
            clamping: model.dataTransferReport.aggregatePathReport.receivedApplicationByteCount)

          processReport.countOfSentBytes -= Int64(
            clamping: dataTransferReport.aggregatePathReport.sentApplicationByteCount)
          processReport.countOfSentBytes &+= Int64(
            clamping: model.dataTransferReport.aggregatePathReport.sentApplicationByteCount)

          processReport.countOfReceivedBytesPerSecond -= Int64(
            clamping: dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0)
          processReport.countOfReceivedBytesPerSecond &+= Int64(
            clamping: model.dataTransferReport.pathReports.first?.receivedApplicationByteCount ?? 0)

          processReport.countOfSentBytesPerSecond -= Int64(
            clamping: dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0)
          processReport.countOfSentBytesPerSecond &+= Int64(
            clamping: model.dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0)

          Task { @MainActor in
            self._processReports[index] = processReport
          }
        } else {
          let index = await self._processReports.firstIndex {
            $0.processName == model.processReport.processName
          }

          if let index {
            var processReport = await self._processReports[index]
            processReport.countOfReceivedBytes &+= Int64(
              clamping: model.dataTransferReport.aggregatePathReport.receivedApplicationByteCount)
            processReport.countOfSentBytes &+= Int64(
              clamping: model.dataTransferReport.aggregatePathReport.sentApplicationByteCount
            )
            processReport.countOfReceivedBytesPerSecond &+= Int64(
              clamping: model.dataTransferReport.pathReports.first?.receivedApplicationByteCount
                ?? 0
            )
            processReport.countOfSentBytesPerSecond &+= Int64(
              clamping: model.dataTransferReport.pathReports.first?.sentApplicationByteCount ?? 0
            )

            Task { @MainActor in
              self._result.append(model)
              self._processReports[index] = processReport
            }
          } else {
            Task { @MainActor in
              self._result.append(model)
              self._processReports
                .append(
                  ProcessReport(
                    processName: model.processReport.processName,
                    processBundleURL: model.processReport.processBundleURL,
                    processExecutableURL: model.processReport.processExecutableURL,
                    processIdentifier: model.processReport.processIdentifier,
                    countOfReceivedBytes: Int64(
                      clamping: model.dataTransferReport.aggregatePathReport
                        .receivedApplicationByteCount
                    ),
                    countOfSentBytes: Int64(
                      clamping: model.dataTransferReport.aggregatePathReport
                        .sentApplicationByteCount
                    ),
                    countOfReceivedBytesPerSecond: Int64(
                      clamping: model.dataTransferReport.pathReports.first?
                        .receivedApplicationByteCount ?? 0
                    ),
                    countOfSentBytesPerSecond: Int64(
                      clamping: model.dataTransferReport.pathReports.first?.sentApplicationByteCount
                        ?? 0
                    )
                  )
                )
            }
          }
        }
      }
    }

    public func erase() {
      self.earliestBeginDate = Date.now
      self._result = []
    }

    public func sortedProcessReports(using options: ProcessReport.CompareOptions) -> [ProcessReport]
    {
      self._processReports.sorted(using: options.sortDescriptor)
    }
  }
#endif
