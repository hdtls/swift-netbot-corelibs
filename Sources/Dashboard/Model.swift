//
// See LICENSE.txt for license information
//

#if swift(>=6.3) || canImport(Darwin)
  import AnlzrReports
  import Dispatch
  import Foundation
  import Logging
  import NEAddressProcessing
  import NIOConcurrencyHelpers
  import Observation

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    import CoreData
    import SwiftData
  #endif

  #if canImport(Network)
    import Network
  #endif

  @available(SwiftStdlib 5.3, *)
  public enum DataTransfer: Hashable, Sendable {
    case upload
    case download
  }

  @available(SwiftStdlib 5.3, *)
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

  @available(SwiftStdlib 5.3, *)
  public protocol ConnectionsDependency: Sendable {

    var messages: AsyncStream<Result<[Connection], LocalizedError>> { get }

    func run()

    func shutdownGracefully()
  }

  @available(SwiftStdlib 5.3, *)
  final private class DefaultConnectionsDependency: ConnectionsDependency {
    public let messages: AsyncStream<Result<[Connection], LocalizedError>>
    private let continuation: AsyncStream<Result<[Connection], LocalizedError>>.Continuation

    #if canImport(Network)
      private let connection = NIOLockedValueBox<NWConnection?>(nil)
    #endif

    private nonisolated let logger = Logger(label: "com.tenbits.netbot.dashboard")

    public init() {
      (messages, continuation) = AsyncStream<Result<[Connection], LocalizedError>>.makeStream()
    }

    #if canImport(Network)
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
                  assertionFailure(
                    "BUG IN NETBOT CORE, please report: illegal data format \(error)")
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
    #else
      public func run() {
        // TODO: WebSocket implementation for non-Darwin platform
      }
    #endif

    public func shutdownGracefully() {}
  }

  @available(SwiftStdlib 5.9, *)
  @MainActor @Observable public class RecentConnectionsStore {

    public typealias Data = Connection.PersistentModel

    nonisolated public static let shared = RecentConnectionsStore()

    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      /// The ModelContainer for the ModelActor.
      /// The container that manages the app’s schema and model storage configuration.
      nonisolated public let modelContainer: ModelContainer
    #else
      public var searchResult: [Data] {
        _searchResult
      }
      private var _searchResult: [Data] = []
      private var _indexes: [Data.ID: Data] = [:]
      @ObservationIgnored private var _activeIndexes: [Data.ID: Data] = [:]

      public var programs: [Program.PersistentModel] {
        _programs
      }
      public var _programs: [Program.PersistentModel] = []
      @ObservationIgnored private var _indexesForPrograms:
        [Program.PersistentModel.ID: Program.PersistentModel] = [:]

      public func fetch(_ id: Data.ID) -> [Data] {
        guard let persistentModel = self._indexes[id] else {
          return []
        }
        return [persistentModel]
      }

      public func fetch(_ id: Program.PersistentModel.ID) -> [Program.PersistentModel] {
        guard let persistentModel = self._indexesForPrograms[id] else {
          return []
        }
        return [persistentModel]
      }
    #endif

    /// An error encountered during the most recent attempt to fetch data.
    ///
    /// This value is `nil` unless an fetch attempt failed. It contains the
    /// latest error from SwiftData.
    public var fetchError: LocalizedError? {
      _fetchError
    }
    private var _fetchError: LocalizedError?

    public var pathReportFormatted: DataTransferReport.PersistentModel.PathReportFormatted {
      _pathReportFormatted
    }
    private var _pathReportFormatted = DataTransferReport.PersistentModel.PathReportFormatted()

    nonisolated private let logger = Logger(label: "com.tenbits.netbot.dashboard")
    nonisolated private let dependency: any ConnectionsDependency
    private var earliestBeginDate = Date.distantPast
    private var _aggregatePathReportTable: [String: DataTransferReport.PathReport] = [:]
    private var timerSource: DispatchSourceTimer?

    nonisolated public convenience init() {
      #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
        let schema = Schema(versionedSchema: V1.self)
        let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
        let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
        self.init(modelContainer: modelContainer, dependency: DefaultConnectionsDependency())
      #else
        self.init(dependency: DefaultConnectionsDependency())
      #endif
    }

    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      nonisolated public init(modelContainer: ModelContainer, dependency: any ConnectionsDependency)
      {
        self.modelContainer = modelContainer
        self.dependency = dependency
      }
    #else
      nonisolated public init(dependency: any ConnectionsDependency) {
        self.dependency = dependency
      }
    #endif

    public func resume() {
      self._fetchError = nil
      self.dependency.run()

      Task.detached { [weak self] in
        guard let self else { return }

        for await message in dependency.messages {
          do {
            let models = try message.get()
            await performBatchUpdates(models)
          } catch {
            logger.error("\(error)")
          }
        }
      }

      timerSource?.cancel()
      timerSource = DispatchSource.makeTimerSource(queue: .main)
      timerSource?.schedule(deadline: .now(), repeating: .seconds(1))
      timerSource?.setEventHandler {
        #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
          let modelContext = self.modelContainer.mainContext

          let term = Connection.State.active.rawValue
          var fd = FetchDescriptor<Data>(predicate: #Predicate { $0._state == term })
          let models: [DataTransferReport.PathReport] =
            (try? modelContext.fetch(fd).compactMap {
              guard let pathReport = $0.dataTransferReport?.pathReport else { return nil }
              return DataTransferReport.PathReport(persistentModel: pathReport)
            }) ?? []
        #else
          let models: [DataTransferReport.PathReport] = self._activeIndexes.compactMap {
            guard let pathReport = $0.value.dataTransferReport?.pathReport else { return nil }
            return DataTransferReport.PathReport(persistentModel: pathReport)
          }
        #endif

        Task.detached {
          let pathReport = models.reduce(DataTransferReport.PathReport()) { $0 &+ $1 }
          let pathReportFormatted = DataTransferReport.PersistentModel.PathReportFormatted(
            sentApplicationByteCount: pathReport.sentApplicationByteCount
              .formatted(.byteCount(style: .binary, spellsOutZero: false)),
            receivedApplicationByteCount: pathReport.receivedApplicationByteCount
              .formatted(.byteCount(style: .binary, spellsOutZero: false))
          )
          await MainActor.run {
            self._pathReportFormatted = pathReportFormatted
          }
        }
      }
      timerSource?.resume()
    }

    public func cancel() {
      self._fetchError = nil
      self.dependency.shutdownGracefully()
    }

    public func aggregatePathReportFormatted(forwardProtocol: String? = nil)
      -> DataTransferReport.PersistentModel.PathReportFormatted
    {
      var aggregatePathReport: DataTransferReport.PathReport

      if let forwardProtocol {
        aggregatePathReport = self._aggregatePathReportTable[forwardProtocol, default: .init()]
      } else {
        aggregatePathReport = self._aggregatePathReportTable.values.reduce(.init()) { $0 &+ $1 }
      }

      return .init(
        sentApplicationByteCount: aggregatePathReport.sentApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false)),
        receivedApplicationByteCount: aggregatePathReport.receivedApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false))
      )
    }

    /// Updates the underlying value of the stored value.
    public func update() {
      self.earliestBeginDate = .distantPast
    }

    public func erase() {
      self.earliestBeginDate = Date.now
    }

    private func performBatchUpdates(_ models: [Connection]) {
      func doInsert(_ model: Connection) throws {
        var persistentModel: V1._Connection
        #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
          let term = model.taskIdentifier
          var fd = FetchDescriptor<V1._Connection>(
            predicate: #Predicate { $0.taskIdentifier == term })
          fd.relationshipKeyPathsForPrefetching = [
            \.currentRequest,
            \.establishmentReport,
            \.response,
            \.processReport,
            \.dataTransferReport,
            \.dataTransferReport?.pathReport,
            \.dataTransferReport?.aggregatePathReport,
          ]
          let _persistentModel = try modelContext.fetch(fd).first
        #else
          let _persistentModel = self._indexes[model.id]
        #endif

        // If a persistent model with the given identifier already exists,
        // merge new values into it (update). Otherwise, create a new
        // persistent model instance for this connection and add it to the
        // relevant collections or persistent store.
        if let _persistentModel {
          persistentModel = _persistentModel
          persistentModel.mergeValues(model)
        } else {
          persistentModel = V1._Connection()
          persistentModel.mergeValues(model)
          #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
            modelContext.insert(persistentModel)
          #else
            self._searchResult.append(persistentModel)
            self._indexes[model.id] = persistentModel
          #endif
        }

        #if !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
          // Track whether this connection is currently active. If so, index
          // for quick access to active connections; otherwise, remove it
          // from the active index.
          if model.state == .establishing || model.state == .active {
            self._activeIndexes[persistentModel.id] = persistentModel
          } else {
            self._activeIndexes[persistentModel.id] = nil
          }
        #endif

        // Insert or update the associated originalRequest persistent model
        // if present in source model.
        //
        // This ensures the connection's originalRequest is accurately
        // reflected in the persistent layer.
        if let backingData = model.originalRequest {
          if persistentModel.originalRequest == nil {
            let originalRequest = Request.PersistentModel()
            originalRequest.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(originalRequest)
            #endif
            persistentModel.originalRequest = originalRequest
          } else {
            persistentModel.originalRequest?.mergeValues(backingData)
          }
        }

        // Insert or update the associated currentRequest persistent model
        // if present in source model.
        //
        // This ensures the connection's currentRequest is accurately
        // reflected in the persistent layer.
        if let backingData = model.currentRequest {
          if persistentModel.currentRequest == nil {
            let currentRequest = Request.PersistentModel()
            currentRequest.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(currentRequest)
            #endif
            persistentModel.currentRequest = currentRequest
          } else {
            persistentModel.currentRequest?.mergeValues(backingData)
          }
        }

        // Insert or update the associated response persistent model
        // if present in source model.
        // This ensures the connection's response is accurately
        // reflected in the persistent layer.
        if let backingData = model.response {
          if persistentModel.response == nil {
            let response = Response.PersistentModel()
            response.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(response)
            #endif
            persistentModel.response = response
          } else {
            persistentModel.response?.mergeValues(backingData)
          }
        }

        // Insert or update the associated forwardingReport persistent
        // model if present in source model.
        //
        // This ensures the connection's forwardingReport is
        // accurately reflected in the persistent layer.
        if let backingData = model.dnsResolutionReport {
          if persistentModel.dnsResolutionReport == nil {
            let dnsResolutionReport = DNSResolutionReport.PersistentModel()
            dnsResolutionReport.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(dnsResolutionReport)
            #endif
            persistentModel.dnsResolutionReport = dnsResolutionReport
          } else {
            persistentModel.dnsResolutionReport?.mergeValues(backingData)
          }
        }

        // Insert or update the associated forwardingReport persistent
        // model if present in source model.
        //
        // This ensures the connection's forwardingReport is
        // accurately reflected in the persistent layer.
        if let backingData = model.forwardingReport {
          if persistentModel.forwardingReport == nil {
            let forwardingReport = ForwardingReport.PersistentModel()
            forwardingReport.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(forwardingReport)
            #endif
            persistentModel.forwardingReport = forwardingReport
          } else {
            persistentModel.forwardingReport?.mergeValues(backingData)
          }
        }

        // Insert or update the associated establishmentReport persistent
        // model if present in source model.
        //
        // This ensures the connection's establishmentReport is
        // accurately reflected in the persistent layer.
        if let backingData = model.establishmentReport {
          if persistentModel.establishmentReport == nil {
            let establishmentReport = EstablishmentReport.PersistentModel()
            establishmentReport.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(establishmentReport)
            #endif
            persistentModel.establishmentReport = establishmentReport
          } else {
            persistentModel.establishmentReport?.mergeValues(backingData)
          }
        }

        // Handle insertion and updates for DataTransferReport and
        // associated path reports.
        //
        // This block manages both creation of new DataTransferReport
        // instances and merging updates into existing ones, while also
        // maintaining aggregate path report data for forwarding protocols.
        if let backingData = model.dataTransferReport {
          if persistentModel.dataTransferReport == nil {
            // If no existing DataTransferReport, create a new one along with
            // its related path reports.
            // Insert these new objects into the model context if applicable.
            // This initializes the data structure necessary to track transfer
            // metrics.
            let dataTransferReport = DataTransferReport.PersistentModel()
            dataTransferReport.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(dataTransferReport)
            #endif

            let aggregatePathReport = V1._PathReport()
            aggregatePathReport.mergeValues(backingData.aggregatePathReport)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(aggregatePathReport)
            #endif
            dataTransferReport.aggregatePathReport = aggregatePathReport

            let pathReport = V1._PathReport()
            pathReport.mergeValues(backingData.pathReport)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(pathReport)
            #endif
            dataTransferReport.pathReport = pathReport

            persistentModel.dataTransferReport = dataTransferReport

            // Update the aggregate path report table for the forwarding
            // protocol or "DIRECT" if none.
            //
            // This allows quick access to cumulative transfer data by protocol.
            let key = model.forwardingReport?.forwardProtocol ?? "DIRECT"
            self._aggregatePathReportTable[key, default: .init()] &+=
              backingData.aggregatePathReport
          } else {
            // If a DataTransferReport already exists, merge new values
            // into it and its path reports.
            //
            // This ensures metrics are kept up to date without losing
            // existing data.
            //
            // The aggregate path report table is updated by adding the new
            // aggregate data and subtracting the old to maintain accurate
            // cumulative totals.
            assert(persistentModel.dataTransferReport?.aggregatePathReport != nil)
            assert(persistentModel.dataTransferReport?.pathReport != nil)
            let aggregatePathReport = DataTransferReport.PathReport(
              persistentModel: persistentModel.dataTransferReport!.aggregatePathReport!
            )

            persistentModel.dataTransferReport?.aggregatePathReport?.mergeValues(
              backingData.aggregatePathReport)
            persistentModel.dataTransferReport?.pathReport?.mergeValues(backingData.pathReport)
            persistentModel.dataTransferReport?.mergeValues(backingData)

            let key = model.forwardingReport?.forwardProtocol ?? "DIRECT"
            self._aggregatePathReportTable[key, default: .init()] &+=
              backingData.aggregatePathReport &- aggregatePathReport
          }
        }

        // Insert or update ProcessReport and handle associated Program linkage.
        // Ensures process records are unique and that data-aggregation for
        // programs is maintained and up-to-date.
        if let backingData = model.processReport {
          if persistentModel.processReport == nil {
            let processReport = ProcessReport.PersistentModel()
            processReport.mergeValues(backingData)
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              modelContext.insert(processReport)
            #else
              // FIXME: Retain Cycle
              processReport.connection = persistentModel
            #endif
            persistentModel.processReport = processReport
          } else {
            persistentModel.processReport?.mergeValues(backingData)
          }

          if let backingData = backingData.program {
            // Prevents duplicate Process objects from being created for the
            // same underlying process.
            var program: Program.PersistentModel
            #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
              let _program = try modelContext.fetch(
                FetchDescriptor<V1._Program>(
                  predicate: #Predicate {
                    $0.localizedName == backingData.localizedName
                  })
              ).first
            #else
              let _program = self._indexesForPrograms[backingData.persistentModelID]
            #endif

            // Ensures that every referenced process actually exists in the database,
            // even if it’s new.
            if let _program {
              program = _program
              if persistentModel.processReport?.program == nil {
                persistentModel.processReport?.program = program
                #if !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
                  // FIXME: Retain Cycle
                  let inserted = program.processReports.contains {
                    $0.connection?.persistentModelID == persistentModel.persistentModelID
                  }
                  if !inserted {
                    program.processReports.append(persistentModel.processReport!)
                  }
                #endif
              }
            } else {
              program = Program.PersistentModel()
              program.mergeValues(backingData)
              #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
                modelContext.insert(program)
              #else
                assert(persistentModel.processReport != nil)
                // FIXME: Retain Cycle
                program.processReports.append(persistentModel.processReport!)
                self._programs.append(program)
                self._indexesForPrograms[backingData.persistentModelID] = program
              #endif
              persistentModel.processReport?.program = program

              let dataTransferReport = V1._DataTransferReport()
              #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
                modelContext.insert(dataTransferReport)
              #endif
              program.dataTransferReport = dataTransferReport

              let aggregatePathReport = V1._PathReport()
              #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
                modelContext.insert(aggregatePathReport)
              #endif
              dataTransferReport.aggregatePathReport = aggregatePathReport

              let pathReport = V1._PathReport()
              #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
                modelContext.insert(pathReport)
              #endif
              dataTransferReport.pathReport = pathReport
            }

            assert(program.dataTransferReport?.aggregatePathReport != nil)
            assert(program.dataTransferReport?.pathReport != nil)
            var aggregatePathReport = DataTransferReport.PathReport()
            var pathReport = DataTransferReport.PathReport()

            for dataTransferReport in program.processReports.compactMap(
              \.connection?.dataTransferReport)
            {
              if let persistentModel = dataTransferReport.aggregatePathReport {
                aggregatePathReport &+= .init(persistentModel: persistentModel)
              }
              if let persistentModel = dataTransferReport.pathReport {
                pathReport &+= .init(persistentModel: persistentModel)
              }
            }

            program.dataTransferReport?.aggregatePathReport?.mergeValues(aggregatePathReport)
            program.dataTransferReport?.pathReport?.mergeValues(pathReport)
            program.dataTransferReport?.aggregatePathReportFormatted = .init(
              sentApplicationByteCount: aggregatePathReport.sentApplicationByteCount
                .formatted(.byteCount(style: .binary, spellsOutZero: false)),
              receivedApplicationByteCount: aggregatePathReport.receivedApplicationByteCount
                .formatted(.byteCount(style: .binary, spellsOutZero: false))
            )
            program.dataTransferReport?.pathReportFormatted = .init(
              sentApplicationByteCount: pathReport.sentApplicationByteCount
                .formatted(.byteCount(style: .binary, spellsOutZero: false)),
              receivedApplicationByteCount: pathReport.receivedApplicationByteCount
                .formatted(.byteCount(style: .binary, spellsOutZero: false))
            )
          }
        }
      }

      #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
        let modelContext = modelContainer.mainContext

        try? modelContext.transaction {
          for model in models {
            try doInsert(model)
          }
        }
      #else
        for model in models {
          try? doInsert(model)
        }
      #endif
    }
  }
#endif
