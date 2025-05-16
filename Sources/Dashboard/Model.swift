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

    fileprivate func insert(_ connection: Connection) {
      let term = connection.taskIdentifier

      var persistentModel: Element
      if let originalModel = query0(filter: #Predicate { $0.taskIdentifier == term }).first {
        persistentModel = originalModel
        persistentModel.mergeValues(connection)
      } else {
        persistentModel = Element()
        persistentModel.mergeValues(connection)
        modelContext.insert(persistentModel)
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @MainActor @Observable public class RecentConnectionsControler {

    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    public static var modelContainer: ModelContainer {
      let schema = Schema(versionedSchema: V1.self)
      let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      return modelContainer
    }

    /// An error encountered during the most recent attempt to fetch data.
    ///
    /// This value is `nil` unless an fetch attempt failed. It contains the
    /// latest error from SwiftData.
    public var fetchError: (any Error)? {
      _fetchError
    }
    @ObservationIgnored private var _fetchError: (any Error)?

    public typealias Result = [Connection]

    private var result: Result = []

    private var filter: ConnectionFilter?

    public var searchResult: Result {
      guard let filter else {
        return result
      }

      let searchResult = result.filter {
        switch filter {
        case .client(let processName):
          guard let processName else {
            return true
          }
          return $0.processReport.processName == processName

        case .hostname(let hostname):
          guard let hostname else {
            return true
          }
          return $0.currentRequest.address?.host(percentEncoded: false) == hostname
        }
      }

      return searchResult
    }

    public var processes: [Connection] {
      var seen = Set<String>()
      return result.filter {
        guard let processName = $0.processReport.processName else {
          return false
        }
        return seen.insert(processName).inserted
      }
    }

    public var hostnames: [String] {
      result.compactMap { $0.currentRequest.host(percentEncoded: false) }.removeDuplicates()
    }

    private nonisolated let store: RecentConnectionsModelActor

    private nonisolated let logger = Logger(
      subsystem: "com.tenbits.netbot.dashboard", category: "connections")

    private let connection: NWConnection

    public init(modelContainer: ModelContainer = modelContainer) {
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
          print("error: \(error)")
        case .preparing:
          break
        case .ready:
          Task.detached {
            await self.runReadLoop()
          }
        case .failed(let error):
          print("error: \(error)")
        case .cancelled:
          break
        @unknown default:
          fatalError()
        }
      }
      connection.start(queue: .global())
    }

    nonisolated private func runReadLoop() async {
      guard await connection.state == .ready else {
        return
      }

      connection.receiveMessage { [weak self] content, contentContext, isComplete, error in
        guard let data = content, let self else {
          return
        }

        Task.detached {
          do {
            let model = try JSONDecoder().decode(Connection.self, from: data)
            await self.store.insert(model)
            await self.update()
          } catch {
            assertionFailure("BUG IN NETBOT CORE, please report: illegal data format \(error)")
            self.logger.critical("decoding connection failure with error: \(error)")
          }

          await self.runReadLoop()
        }
      }
    }

    /// Query results with a predicate.
    @discardableResult
    public func query(filter: ConnectionFilter?) -> Result {
      self.filter = filter
      return searchResult
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
        self._fetchError = fetchError
        self.result = result
      }
    }

    public func erase() async {
      result = []
    }
  }
#endif
