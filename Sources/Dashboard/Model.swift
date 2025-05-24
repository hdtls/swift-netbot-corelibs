//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import AnlzrReports
  import CoreData
  import Dispatch
  import Foundation
  import NEAddressProcessing
  import Network
  import Observation
  import SwiftData
  import os

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @ModelActor private actor RecentConnectionsModelActor {
    typealias Element = Connection.PersistentModel

    /// An error encountered during the most recent attempt to fetch data.
    var fetchError: (any Error)?

    func query<Value>(
      filter: Predicate<Element>? = nil, sort keyPath: KeyPath<Element, Value> & Sendable,
      order: SortOrder = .forward
    ) -> [Connection] where Value: Comparable {
      var fd = FetchDescriptor<Element>()
      fd.predicate = filter
      fd.sortBy = [SortDescriptor(keyPath, order: order)]
      return query(fd)
    }

    func query<Value>(
      filter: Predicate<Element>? = nil, sort keyPath: KeyPath<Element, Value?> & Sendable,
      order: SortOrder = .forward
    ) -> [Connection] where Value: Comparable {
      var fd = FetchDescriptor<Element>()
      fd.predicate = filter
      fd.sortBy = [SortDescriptor(keyPath, order: order)]
      return query(fd)
    }

    func query(filter: Predicate<Element>? = nil, sort descriptors: [SortDescriptor<Element>] = [])
      -> [Connection]
    {
      var fd = FetchDescriptor<Element>()
      fd.predicate = filter
      fd.sortBy = descriptors
      return query(fd)
    }

    func query(_ descriptor: FetchDescriptor<Element>) -> [Connection] {
      do {
        return try modelContext.fetch(descriptor).map(Connection.init)
      } catch {
        fetchError = error
        return []
      }
    }

    private func query0(filter: Predicate<Element>) -> [Element] {
      do {
        var fd = FetchDescriptor<Element>()
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
          let index = models.firstIndex(where: { $0.taskIdentifier == connection.taskIdentifier })
          if let index {
            models[index].mergeValues(connection)
          } else {
            let persistentModel = Element()
            persistentModel.mergeValues(connection)
            modelContext.insert(persistentModel)
          }
        }
      }
      try? modelContext.save()
    }
  }

  public enum RecentConnectionsError: Error {
    case operationUnsupported
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @MainActor @Observable public class RecentConnectionsControler {

    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    public var modelContainer: ModelContainer {
      store.modelContainer
    }

    /// An error encountered during the most recent attempt to fetch data.
    ///
    /// This value is `nil` unless an fetch attempt failed. It contains the
    /// latest error from SwiftData.
    public var fetchError: (any Error)? {
      _fetchError
    }
    private var _fetchError: (any Error)?

    public typealias Result = [Connection]

    public var result: Result {
      _result
    }
    private var _result: Result = []

    private nonisolated let store: RecentConnectionsModelActor

    private nonisolated let logger = Logger(
      subsystem: "com.tenbits.netbot.dashboard", category: "connections")

    private let connection: NWConnection

    @ObservationIgnored private var earliestBeginDate = Date.distantPast

    nonisolated public convenience init() {
      let schema = Schema(versionedSchema: V1.self)
      let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      self.init(modelContainer: modelContainer)
    }

    nonisolated public init(modelContainer: ModelContainer) {
      store = RecentConnectionsModelActor(modelContainer: modelContainer)

      let parameters = NWParameters.tcp
      let options = NWProtocolWebSocket.Options()
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
      connection = NWConnection(to: .url(URL(string: "ws://127.0.0.1:6170")!), using: parameters)

      Task {
        await self.update()
      }

      connection.stateUpdateHandler = { state in
        switch state {
        case .setup:
          break
        case .waiting(let error):
          Task { @MainActor in
            self._fetchError = error
          }
        case .preparing:
          break
        case .ready:
          Task.detached {
            await self.runReadLoop()
          }
        case .failed(let error):
          Task { @MainActor in
            self._fetchError = error
          }
        case .cancelled:
          break
        @unknown default:
          Task { @MainActor in
            self._fetchError = RecentConnectionsError.operationUnsupported
          }
        }
      }
      connection.start(queue: .global())
    }

    nonisolated private func runReadLoop() async {
      guard connection.state == .ready else {
        return
      }

      connection.receiveMessage { [weak self] content, contentContext, isComplete, error in
        guard let data = content, let self else {
          return
        }

        Task.detached {
          do {
            let models = try JSONDecoder().decode([Connection].self, from: data)
            await self.store.insert(models)
            await self.insert(models)
          } catch {
            assertionFailure("BUG IN NETBOT CORE, please report: illegal data format \(error)")
            self.logger.critical("decoding connection failure with error: \(error)")
          }

          await self.runReadLoop()
        }
      }
    }

    public func search(tokens: [ConnectionFilter]) -> Result {
      var predicate: ((Result.Element) -> Bool)?
      if let token = tokens.first {
        switch token {
        case .client(let processName):
          if let processName {
            predicate = { $0.processReport.processName == processName }
          }
        case .hostname(let hostname):
          if let hostname {
            predicate = { $0.originalRequest.host(percentEncoded: false) == hostname }
          }
        }
      }

      if let predicate {
        return result.filter(predicate)
      }
      return result
    }

    /// Updates the underlying value of the stored value.
    nonisolated public func update() async {
      var fd = FetchDescriptor<Connection.PersistentModel>()
      fd.propertiesToFetch = [
        \.taskIdentifier, \.earliestBeginDate, \.state, \._forwardingReport, \._dataTransferReport,
      ]
      fd.relationshipKeyPathsForPrefetching = [
        \._originalRequest, \._currentRequest, \._establishmentReport, \._processReport,
      ]
      fd.sortBy = [SortDescriptor(\.taskIdentifier)]

      let result = await store.query(fd)
      let fetchError = await store.fetchError

      Task { @MainActor in
        self.earliestBeginDate = .distantPast
        self._fetchError = fetchError
        self._result = result
      }
    }

    private func insert(_ models: [Connection]) {
      for model in models where model.earliestBeginDate > earliestBeginDate {
        if let index = result.firstIndex(where: { $0.id == model.id }) {
          self._result[index].originalRequest = model.originalRequest
          self._result[index].currentRequest = model.currentRequest
          self._result[index].response = model.response
          self._result[index].earliestBeginDate = model.earliestBeginDate
          self._result[index].taskDescription = model.taskDescription
          self._result[index].tls = model.tls
          self._result[index].state = model.state
          self._result[index].establishmentReport = model.establishmentReport
          self._result[index].forwardingReport = model.forwardingReport
          self._result[index].dataTransferReport = model.dataTransferReport
          self._result[index].processReport = model.processReport
        } else {
          self._result.append(model)
        }
      }
    }

    public func erase() {
      self.earliestBeginDate = Date.now
      self._result = []
    }
  }
#endif
