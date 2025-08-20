//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
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

  final private class DefaultConnectionsDependency: ConnectionsDependency {
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
  @MainActor @Observable public class RecentConnectionsStore {

    public typealias Data = Connection.PersistentModel

    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    nonisolated public let modelContainer: ModelContainer

    /// An error encountered during the most recent attempt to fetch data.
    ///
    /// This value is `nil` unless an fetch attempt failed. It contains the
    /// latest error from SwiftData.
    public var fetchError: LocalizedError? {
      _fetchError
    }
    private var _fetchError: LocalizedError?

    public var totalBytesTransferred: DataTransferReport.PathReport {
      _totalBytesTransferred
    }
    private var _totalBytesTransferred = DataTransferReport.PathReport()

    public var bytesTransferred: DataTransferReport.PathReport {
      _bytesTransferred
    }
    private var _bytesTransferred = DataTransferReport.PathReport()

    nonisolated private let logger = Logger(label: "com.tenbits.netbot.dashboard")
    nonisolated private let dependency: any ConnectionsDependency
    private var earliestBeginDate = Date.distantPast

    nonisolated public convenience init() {
      let schema = Schema(versionedSchema: V1.self)
      let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      self.init(modelContainer: modelContainer, dependency: DefaultConnectionsDependency())
    }

    nonisolated public init(modelContainer: ModelContainer, dependency: any ConnectionsDependency) {
      self.modelContainer = modelContainer
      self.dependency = dependency
    }

    public func resume() {
      self._fetchError = nil
      self.dependency.run()

      Task { [weak self] in
        guard let self else { return }

        for await message in dependency.messages {
          do {
            try await performBatchUpdates(message.get())
          } catch {
            logger.error("\(error)")
          }
        }
      }
    }

    public func cancel() {
      self._fetchError = nil
      self.dependency.shutdownGracefully()
    }

    public func search(tokens: [ConnectionFilter]) -> Predicate<Data> {
      let options = tokens.first
      switch options {
      case .none: break
      case .some(.client(let processName)):
        if let processName {
          return #Predicate {
            if $0.earliestBeginDate < earliestBeginDate {
              return false
            } else {
              if let processReport = $0.processReport, let program = processReport.program {
                return program.localizedName == processName
              } else {
                return false
              }
            }
          }
        }
      case .some(.hostname(let hostname)):
        if let hostname {
          return #Predicate {
            $0.earliestBeginDate >= earliestBeginDate && $0.currentRequest?.hostname == hostname
          }
        }
      }

      return #Predicate { $0.earliestBeginDate >= earliestBeginDate }
    }

    /// Updates the underlying value of the stored value.
    public func update() {
      self.earliestBeginDate = .distantPast
    }

    public func erase() {
      self.earliestBeginDate = Date.now
    }

    private func performBatchUpdates(_ models: [Connection]) {
      let modelContext = modelContainer.mainContext

      for model in models {
        var fd = FetchDescriptor<Data>()
        fd.relationshipKeyPathsForPrefetching = [\.dataTransferReport]
        fd.predicate = #Predicate { $0.taskIdentifier == model.taskIdentifier }
        if let persistentModel = try? modelContext.fetch(fd).first {
          switch (
            persistentModel.dataTransferReport?.aggregatePathReport,
            model.dataTransferReport?.aggregatePathReport
          ) {
          case (.some(let lhs), .some(let rhs)):
            self._totalBytesTransferred &+= rhs &- lhs
          case (.none, .some(let rhs)):
            self._totalBytesTransferred &+= rhs
          case (.some(let lhs), .none): break
          case (.none, .none): break
          }

          switch (
            persistentModel.dataTransferReport?.pathReports.first,
            model.dataTransferReport?.pathReports.first
          ) {
          case (.some(let lhs), .some(let rhs)):
            self._bytesTransferred &+= rhs &- lhs
          case (.none, .some(let rhs)):
            self._bytesTransferred &+= rhs
          case (.some(let lhs), .none): break
          case (.none, .none): break
          }
        } else {
          if let aggregatePathReport = model.dataTransferReport?.aggregatePathReport {
            self._totalBytesTransferred &+= aggregatePathReport
          }
          if let pathReport = model.dataTransferReport?.pathReports.first {
            self._bytesTransferred &+= pathReport
          }
        }
      }

      try? modelContext.transaction {
        try Dashboard._insertREQs(models, modelContext: modelContext)
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @inlinable public func _insertREQs(
    _ models: [Connection], modelContext: ModelContext
  ) throws {
    func doInsert(_ model: Connection) throws {
      let term = model.taskIdentifier
      var fd = FetchDescriptor<V1._Connection>(predicate: #Predicate { $0.taskIdentifier == term })
      fd.relationshipKeyPathsForPrefetching = [
        \.currentRequest,
        \.establishmentReport,
        \.response,
        \.processReport,
      ]

      var persistentModel = try modelContext.fetch(fd).first
      if persistentModel == nil {
        persistentModel = V1._Connection()
        modelContext.insert(persistentModel.unsafelyUnwrapped)
      }
      persistentModel?.mergeValues(model)

      if let backingData = model.originalRequest {
        if persistentModel?.originalRequest == nil {
          persistentModel?.originalRequest = Request.PersistentModel()
        }
        persistentModel?.originalRequest?.mergeValues(backingData)
      }

      if let backingData = model.currentRequest {
        if persistentModel?.currentRequest == nil {
          persistentModel?.currentRequest = Request.PersistentModel()
        }
        persistentModel?.currentRequest?.mergeValues(backingData)
      }

      if let backingData = model.response {
        if persistentModel?.response == nil {
          persistentModel?.response = Response.PersistentModel()
        }
        persistentModel?.response?.mergeValues(backingData)
      }

      if let backingData = model.establishmentReport {
        if persistentModel?.establishmentReport == nil {
          persistentModel?.establishmentReport = EstablishmentReport.PersistentModel()
        }
        persistentModel?.establishmentReport?.mergeValues(backingData)
      }

      if let backingData = model.processReport {
        if persistentModel?.processReport == nil {
          persistentModel?.processReport = ProcessReport.PersistentModel()
        }
        persistentModel?.processReport?.mergeValues(backingData)

        // Prevents duplicate Process objects from being created for the same underlying process.
        var process = try modelContext.fetch(
          FetchDescriptor<V1._Program>(
            predicate: #Predicate {
              $0.localizedName == backingData.program?.localizedName ?? "Unkown"
            })
        ).first

        // Ensures that every referenced process actually exists in the database, even if it’s new.
        if process == nil {
          process = .init()
          process?.localizedName = backingData.program?.localizedName ?? "Unkown"
          modelContext.insert(process.unsafelyUnwrapped)
        }

        // Guarantees that the Connection → ProcessReport → Process relationship chain is
        // established.
        if persistentModel?.processReport?.program == nil {
          persistentModel?.processReport?.program = process
        }

        // Ensures the stored process object remains up-to-date.
        if let backingData = backingData.program {
          process?.mergeValues(backingData)
        }
      }
    }

    for model in models {
      try doInsert(model)
    }
  }
#endif
