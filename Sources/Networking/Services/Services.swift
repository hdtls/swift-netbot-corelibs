//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AnlzrReports
import NIOConcurrencyHelpers

@available(SwiftStdlib 5.3, *)
public protocol Service {
  func run0() async throws
  func shutdownGracefully0() async
}

@available(SwiftStdlib 5.3, *)
extension Service {
  public func run0() async throws {}
  public func shutdownGracefully0() async {}
}

@available(SwiftStdlib 5.3, *)
extension Analyzer {

  public struct Services {

    /// Service provider.
    public struct ServiceProvider<S> {

      let application: Analyzer

      /// Create generic service with specific application.
      public init(application: Analyzer) {
        self.application = application
      }

      /// We can make this unchecked as we're only storing a sendable closure and mutation is protected by the lock
      final class _Storage: StorageValue, @unchecked Sendable {
        // At first glance, one could think that using a
        // `NIOLockedValueBox<(@Sendable (Analyzer) -> S)?>` for `makeService` would be sufficient
        // here. However, for some reason, caling `self.storage.makeService.withLockedValue({ $0 })` repeatedly in
        // `Service.service` causes each subsequent call to the function stored inside the locked value to perform
        // one (or several) more "trampoline" function calls, slowing down the execution and eventually leading to a
        // stack overflow. This is why we use a `NIOLock` here instead; it seems to avoid the `{ $0 }` issue above
        // despite still accessing `_makeService` from within a closure (`{ self._makeService }`).
        let lock = NIOLock()

        private var _makeService: @Sendable (Analyzer) -> S
        var makeService: @Sendable (Analyzer) -> S {
          get { self.lock.withLock { self._makeService } }
          set { self.lock.withLock { self._makeService = newValue } }
        }

        private weak var application: Analyzer?

        fileprivate init(application: Analyzer) {
          self.application = application
          self._makeService = { _ in fatalError("Service \(Service.self) not configured.") }
        }

        func run0() async throws {
          guard let application else { return }
          if let service = makeService(application) as? Service {
            try await service.run0()
          }
        }

        func shutdownGracefully0() async {
          guard let application else { return }
          if let service = makeService(application) as? Service {
            await service.shutdownGracefully0()
          }
        }
      }

      struct Key: StorageKey {
        typealias Value = _Storage
      }

      /// Service initialized by provided factory.
      public var service: S {
        self.storage.makeService(self.application)
      }

      /// Register service factory.
      public func use(_ makeService: @escaping @Sendable (Analyzer) -> S) {
        self.storage.makeService = makeService
      }

      @discardableResult
      private func initialize() -> _Storage {
        self.application._storage.withLock {
          let new = _Storage(application: application)
          $0[Key.self] = new
          return new
        }
      }

      private var storage: _Storage {
        if let storage = application._storage.withLock({ $0[Key.self] }) {
          return storage
        } else {
          return self.initialize()
        }
      }
    }

    public let application: Analyzer
  }

  /// A groups for access all registered services.
  public var services: Services {
    .init(application: self)
  }
}
