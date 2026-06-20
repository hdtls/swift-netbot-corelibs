// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Alamofire
import Logging
import NetbotLiteData
import Synchronization

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import CoreData
  import SwiftData
#endif

#if canImport(NetworkExtension)
  import NetworkExtension
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

@available(SwiftStdlib 6.0, *)
public enum DataTransfer: Hashable, Sendable {
  case upload
  case download
}

@available(SwiftStdlib 6.0, *)
#if canImport(Darwin) || swift(>=6.3)
  @Observable
#endif
@MainActor public class RecentConnectionsStore {

  public typealias Data = Connection.Model

  nonisolated public static let `default` = RecentConnectionsStore()

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    /// The ModelContainer for the ModelActor.
    /// The container that manages the app’s schema and model storage configuration.
    nonisolated public let modelContainer: ModelContainer
  #else
    public var searchResult: [Data] {
      _searchResult
    }
    private var _searchResult: [Data] = []
    private var _indexes: [Data.ID: Data] = [:]

    #if canImport(Darwin) || swift(>=6.3)
      @ObservationIgnored private var _activeIndexes: [Data.ID: Data] = [:]
    #else
      private var _activeIndexes: [Data.ID: Data] = [:]
    #endif

    public var programs: [Program.Model] {
      _programs
    }
    public var _programs: [Program.Model] = []

    #if canImport(Darwin) || swift(>=6.3)
      @ObservationIgnored private var _indexesForPrograms: [Program.Model.ID: Program.Model] = [:]
    #else
      private var _indexesForPrograms: [Program.Model.ID: Program.Model] = [:]
    #endif

    public func fetch(_ id: Data.ID) -> [Data] {
      guard let persistentModel = self._indexes[id] else {
        return []
      }
      return [persistentModel]
    }

    public func fetch(_ id: Program.Model.ID) -> [Program.Model] {
      guard let persistentModel = self._indexesForPrograms[id] else {
        return []
      }
      return [persistentModel]
    }
  #endif

  /// An error encountered during the most recent attempt to fetch data.
  ///
  /// This value is `nil` unless an fetch attempt failed.
  public var fetchError: AFError? { _fetchError }
  private var _fetchError: AFError?

  /// A boolean value determine whether fech operation is interrupted by error.
  public var isInterrupted: Bool {
    _fetchError != nil
  }

  public var pathReportFormatted: DataTransferReport.PathReport.Model.Formatted {
    _pathReportFormatted
  }
  private var _pathReportFormatted = DataTransferReport.PathReport.Model.Formatted()

  nonisolated private let logger = Logger(label: "dashboard")
  nonisolated private let messenger: any MessengerProtocol
  private var earliestBeginDate = Date.distantPast
  private let pathReportTable = Mutex<[String: DataTransferReport.PathReport]>([:])
  private var speedProcessTask: Task<Void, Never>?
  private var fetchTask: Task<Void, Never>?

  #if canImport(NetworkExtension)
    #if swift(>=6.2)
      private var vpnStatusObservationTask: Task<Void, Never>?
    #else
      nonisolated private let vpnStatusObservationTask: Mutex<Task<Void, Never>?>
    #endif
  #endif

  nonisolated public convenience init() {
    self.init(messenger: Messenger())
  }

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    nonisolated public convenience init(
      modelContainer: ModelContainer, messenger: some MessengerProtocol
    ) {
      self.init(_modelContainer: modelContainer, messenger: messenger)
    }
  #endif

  nonisolated public convenience init(messenger: some MessengerProtocol) {
    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      let schema = Schema(versionedSchema: V1.self)
      let configuration: ModelConfiguration = .init(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      self.init(_modelContainer: modelContainer, messenger: messenger)
    #else
      self.init(_modelContainer: nil, messenger: messenger)
    #endif
  }

  nonisolated private init(_modelContainer: Any?, messenger: some MessengerProtocol) {
    self.messenger = messenger
    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      self.modelContainer = _modelContainer as! ModelContainer
    #endif

    #if canImport(NetworkExtension)
      let task = Task { [weak self] in
        for await notification in NotificationCenter.default.notifications(
          named: .NEVPNStatusDidChange)
        {
          guard let self, let connection = notification.object as? NEVPNConnection else {
            return
          }
          switch connection.status {
          case .disconnected:
            await MainActor.run {
              self.cancel()
            }
          case .connected:
            await MainActor.run {
              self.resume()
            }
          default:
            break
          }
        }
      }

      #if swift(>=6.2)
        Task { @MainActor [weak self] in
          self?.vpnStatusObservationTask = task
        }
      #else
        self.vpnStatusObservationTask = .init(nil)
        self.vpnStatusObservationTask.withLock { $0 = task }
      #endif
    #endif
  }

  public func resume() {
    // Operation only permitted when fetch task is nil or original task is cancelled.
    guard self.fetchTask?.isCancelled ?? true else { return }
    self.fetchTask = Task { [weak self] in
      guard let self else { return }

      do {
        for try await message in messenger.openStream() {
          await performBatchUpdates(message)
        }
      } catch let error as AFError {
        self._fetchError = error
        self.fetchTask?.cancel()
        self.fetchTask = nil
        logger.error("\(error)")
      } catch {
        logger.error("\(error)")
      }
    }

    self._fetchError = nil

    if let speedProcessTask, !speedProcessTask.isCancelled {
      speedProcessTask.cancel()
    }
    self.speedProcessTask = Task.detached {
      #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
        let modelContext = ModelContext(self.modelContainer)
      #endif

      while !Task.isCancelled {
        #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
          let term = Connection.State.active.rawValue
          let fd = FetchDescriptor<Data>(predicate: #Predicate { $0._state == term })
          let models: [DataTransferReport.PathReport] =
            (try? modelContext.fetch(fd).compactMap {
              guard let pathReport = $0.dataTransferReport?.pathReport else { return nil }
              return DataTransferReport.PathReport(persistentModel: pathReport)
            }) ?? []
        #else
          let models: [DataTransferReport.PathReport] = await Task { @MainActor in
            self._activeIndexes.compactMap {
              guard let pathReport = $0.value.dataTransferReport?.pathReport else { return nil }
              return DataTransferReport.PathReport(persistentModel: pathReport)
            }
          }.value
        #endif
        let pathReport = models.reduce(DataTransferReport.PathReport()) { $0 &+ $1 }
        let pathReportFormatted = DataTransferReport.PathReport.Model.Formatted(
          sentApplicationByteCount: pathReport.sentApplicationByteCount
            .formatted(.byteCount(style: .binary, spellsOutZero: false)),
          receivedApplicationByteCount: pathReport.receivedApplicationByteCount
            .formatted(.byteCount(style: .binary, spellsOutZero: false))
        )
        Task { @MainActor in
          self._pathReportFormatted = pathReportFormatted
        }
        try? await Task.sleep(for: .seconds(1), clock: .suspending)
      }

      let pathReportFormatted = DataTransferReport.PathReport.Model.Formatted()
      Task { @MainActor in
        self._pathReportFormatted = pathReportFormatted
      }
    }
  }

  private func cancel() {
    self.speedProcessTask?.cancel()
    self.fetchTask?.cancel()
    self.fetchTask = nil
  }

  public func aggregatePathReportFormatted(forwardProtocol: String? = nil)
    -> DataTransferReport.PathReport.Model.Formatted
  {
    var aggregatePathReport: DataTransferReport.PathReport

    if let forwardProtocol {
      aggregatePathReport = self.pathReportTable.withLock {
        $0[forwardProtocol, default: .init()]
      }
    } else {
      aggregatePathReport = self.pathReportTable.withLock {
        $0.values.reduce(.init()) { $0 &+ $1 }
      }
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

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    #if swift(>=6.2)
      @concurrent
    #endif
  #endif
  private func performBatchUpdates(_ models: [Connection]) async {
    func doInsert(_ model: Connection) throws {
      var persistentModel: V1.Connection
      #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
        let term = model.taskIdentifier
        var fd = FetchDescriptor<V1.Connection>(
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
        persistentModel = V1.Connection()
        persistentModel.mergeValues(model)
        #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
          modelContext.insert(persistentModel)
        #else
          self._searchResult.append(persistentModel)
          self._indexes[model.id] = persistentModel
        #endif
      }

      #if !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
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
          let originalRequest = Request.Model()
          originalRequest.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let currentRequest = Request.Model()
          currentRequest.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let response = Response.Model()
          response.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let dnsResolutionReport = DNSResolutionReport.Model()
          dnsResolutionReport.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let forwardingReport = ForwardingReport.Model()
          forwardingReport.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let establishmentReport = EstablishmentReport.Model()
          establishmentReport.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          let dataTransferReport = DataTransferReport.Model()
          dataTransferReport.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
            modelContext.insert(dataTransferReport)
          #endif

          let aggregatePathReport = V1.PathReport()
          aggregatePathReport.mergeValues(backingData.aggregatePathReport)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
            modelContext.insert(aggregatePathReport)
          #endif
          dataTransferReport.aggregatePathReport = aggregatePathReport

          let pathReport = V1.PathReport()
          pathReport.mergeValues(backingData.pathReport)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
            modelContext.insert(pathReport)
          #endif
          dataTransferReport.pathReport = pathReport

          persistentModel.dataTransferReport = dataTransferReport

          // Update the aggregate path report table for the forwarding
          // protocol or "DIRECT" if none.
          //
          // This allows quick access to cumulative transfer data by protocol.
          let key = model.forwardingReport?.forwardProtocol ?? "DIRECT"
          self.pathReportTable.withLock {
            $0[key, default: .init()] &+= backingData.aggregatePathReport
          }
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

          persistentModel.dataTransferReport?.mergeValues(backingData)
          persistentModel.dataTransferReport?.aggregatePathReport?.mergeValues(
            backingData.aggregatePathReport)
          persistentModel.dataTransferReport?.pathReport?.mergeValues(backingData.pathReport)

          let key = model.forwardingReport?.forwardProtocol ?? "DIRECT"
          self.pathReportTable.withLock {
            $0[key, default: .init()] &+= backingData.aggregatePathReport &- aggregatePathReport
          }
        }
      }

      // Insert or update ProcessReport and handle associated Program linkage.
      // Ensures process records are unique and that data-aggregation for
      // programs is maintained and up-to-date.
      if let backingData = model.processReport {
        if persistentModel.processReport == nil {
          let processReport = ProcessReport.Model()
          processReport.mergeValues(backingData)
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
          var program: Program.Model
          #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
            let _program = try modelContext.fetch(
              FetchDescriptor<V1.Program>(
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
              #if !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
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
            program = Program.Model()
            program.mergeValues(backingData)
            #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
              modelContext.insert(program)
            #else
              assert(persistentModel.processReport != nil)
              // FIXME: Retain Cycle
              program.processReports.append(persistentModel.processReport!)
              self._programs.append(program)
              self._indexesForPrograms[backingData.persistentModelID] = program
            #endif
            persistentModel.processReport?.program = program

            let dataTransferReport = V1.DataTransferReport()
            #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
              modelContext.insert(dataTransferReport)
            #endif
            program.dataTransferReport = dataTransferReport

            let aggregatePathReport = V1.PathReport()
            #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
              modelContext.insert(aggregatePathReport)
            #endif
            dataTransferReport.aggregatePathReport = aggregatePathReport

            let pathReport = V1.PathReport()
            #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
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
        }
      }
    }

    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      let modelContext = ModelContext(modelContainer)

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
