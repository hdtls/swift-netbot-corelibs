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

  var messages: AsyncThrowingStream<[Connection], any Error> { get }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class Messenger: MessengerProtocol {

  private typealias Model = Connection

  @LockableTracked private var rateLimited: [Model.ID: Model] = [:]

  public var messages: AsyncThrowingStream<[Connection], any Error> {
    AsyncThrowingStream { continuation in
      _ = Task.detached {
        while true {
          self.$rateLimited.withLock {
            if !$0.isEmpty {
              continuation.yield(Array($0.values))
            }
          }
          try await Task.sleep(for: .seconds(1))
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

            self.$rateLimited.withLock { rateLimited in
              var models: [Model] = []
              for model in value {
                // If `rateLimited` does not contains `model`, we should immediately
                // yield this model as it's a new request.
                guard rateLimited[model.id] != nil else {
                  models.append(model)

                  if !model.state.isFinished {
                    rateLimited[model.id] = model
                  }
                  continue
                }

                guard model.state.isFinished else {
                  rateLimited[model.id] = model
                  continue
                }

                models.append(model)
                rateLimited.removeValue(forKey: model.id)
              }

              continuation.yield(models)
            }
          }
      //        let parameters = NWParameters.tcp
      //        let options = NWProtocolWebSocket.Options()
      //        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
      //        let connection = NWConnection(
      //          to: .url(URL(string: "ws://127.0.0.1:6170")!),
      //          using: parameters
      //        )
      //
      //        continuation.onTermination = { _ in
      //          connection.cancel()
      //        }
      //
      //        connection.stateUpdateHandler = { state in
      //          switch state {
      //          case .setup, .waiting, .preparing:
      //            break
      //          case .ready:
      //            @Sendable func runReadLoop() {
      //              guard connection.state == .ready else {
      //                return
      //              }
      //
      //              connection.receiveMessage { content, _, _, error in
      //                guard let data = content else {
      //                  return
      //                }
      //
      //                do {
      //                  let models = try JSONDecoder().decode([Connection].self, from: data)
      //                  continuation.yield(models)
      //                } catch {
      //                  assertionFailure(
      //                    "BUG IN NETBOT CORE, please report: illegal data format \(error)")
      //                }
      //
      //                runReadLoop()
      //              }
      //            }
      //
      //            runReadLoop()
      //          case .failed(let error):
      //            continuation.finish(throwing: LocalizedError.nw(error))
      //          case .cancelled:
      //            // We have finished continuation immediately when shutdown, so there we do nothing.
      //            continuation.finish(throwing: LocalizedError.nw(.posix(.ECANCELED)))
      //          @unknown default:
      //            continuation.finish(throwing: LocalizedError.operationUnsupported)
      //          }
      //        }
      //        connection.start(queue: .global())
      #else
        continuation.finish()
      #endif
    }
  }

  init() {}
}
