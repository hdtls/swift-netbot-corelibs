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

import NetbotLiteData
import SynchronizationExtras

#if canImport(Darwin)
  @_spi(WebSocket) import Alamofire
  import Dispatch
#else
  import Alamofire
#endif

#if !canImport(Darwin) || !NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol MessengerProtocol: Sendable {

  func openStream() -> AsyncThrowingStream<[Connection], any Error>
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class Messenger: MessengerProtocol {

  private typealias Model = Connection

  @LockableTracked private var rateLimited: [Model.ID: Model] = [:]

  enum RateLimiting: Sendable {
    case immediately
    case seconds(Int)
  }

  private let rateLimiting: RateLimiting

  init(rateLimiting: RateLimiting = .seconds(1)) {
    self.rateLimiting = rateLimiting
  }

  public func openStream() -> AsyncThrowingStream<[Connection], any Error> {
    AsyncThrowingStream { continuation in
      if case .seconds(let seconds) = self.rateLimiting {
        _ = Task.detached {
          while true {
            self.$rateLimited.withLock {
              if !$0.isEmpty {
                continuation.yield(Array($0.values))
              }
            }
            try await Task.sleep(for: .seconds(seconds))
          }
        }
      }

      #if canImport(Darwin)
        Session.default
          .webSocketRequest(to: "ws://127.0.0.1:6170")
          .streamDecodableEvents([Connection].self, on: .global()) { event in
            if case .completed(let completion) = event.kind {
              guard let error = completion.error else {
                continuation.finish()
                return
              }
              continuation.finish(throwing: error)
              return
            }

            guard let value = event.message else {
              return
            }

            switch self.rateLimiting {
            case .immediately:
              continuation.yield(value)
            case .seconds:
              self.$rateLimited.withLock { rateLimited in
                var models: [Model] = []
                for model in value {
                  guard rateLimited[model.id] != nil else {
                    // If `rateLimited` does not contains `model`, we should immediately
                    // yield this model as it's a new request.
                    models.append(model)

                    // We don't store request that is finished.
                    if !model.state.isFinished {
                      rateLimited[model.id] = model
                    }
                    continue
                  }

                  guard model.state.isFinished else {
                    // Store incoming request which is not finished.
                    rateLimited[model.id] = model
                    continue
                  }

                  models.append(model)
                  // The incoming request is finished and no longer changed, so we can remove it
                  // from `rateLimited`.
                  rateLimited.removeValue(forKey: model.id)
                }

                continuation.yield(models)
              }
            }
          }
      #else
        continuation.finish()
      #endif
    }
  }
}
