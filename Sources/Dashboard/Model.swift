//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import AnlzrReports
  import CoreData
  import Dispatch
  import Foundation
  import Observation
  import SwiftData
  import NEAddressProcessing

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
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @MainActor @Observable public class RecentConnectionsControler {

    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    public static var modelContainer: ModelContainer {
      let schema = Schema(versionedSchema: V1.self)
      let configuration: ModelConfiguration

      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.tenbits.netbot"
      )
      if let containerURL {
        let url: URL
        let pathComponent = "/Library/Caches/Netbot/analyzed.store"
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
          url = containerURL.appending(component: pathComponent)
        } else {
          url = containerURL.appendingPathComponent(pathComponent)
        }
        configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
      } else {
        configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      }
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

    private let store: RecentConnectionsModelActor

    @ObservationIgnored private var task: Task<Void, any Error>?

    public init(modelContainer: ModelContainer = modelContainer) {
      store = RecentConnectionsModelActor(modelContainer: modelContainer)

      Task {
        await self.update()
      }

      task = Task.detached(priority: .background) { [weak self] in
        let nc = NotificationCenter.default
        for await _ in nc.notifications(named: .NSPersistentStoreRemoteChange).map(\.name) {
          await self?.update()
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
