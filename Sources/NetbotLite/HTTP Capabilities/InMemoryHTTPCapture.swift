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

import HTTPTypes
import NIOCore
import NIOHTTP1
import NIOHTTPTypesHTTP1
import NetbotLiteData
import Synchronization

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
final class InMemoryHTTPCapture<HeadT: Equatable & Sendable>: ChannelInboundHandler, Sendable {

  typealias InboundIn = HTTPPart<HeadT, ByteBuffer>
  typealias InboundOut = HTTPPart<HeadT, IOData>

  private let inMemoryHTTPCaptureFilters: [String]
  private let connection: Connection

  init(connection: Connection, captureFilters: [String]) {
    self.connection = connection
    self.inMemoryHTTPCaptureFilters = captureFilters

    guard HeadT.self == HTTPRequestHead.self || HeadT.self == HTTPResponseHead.self else {
      preconditionFailure("unknown HTTP head part type \(HeadT.self)")
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    context.fireChannelRead(data)

    let unwrapped = unwrapInboundIn(data)
    switch unwrapped {
    case .head(let head):
      if HeadT.self == HTTPRequestHead.self {
        let partialResult = try? HTTPRequest(
          head as! HTTPRequestHead,
          secure: connection.tls,
          splitCookie: false
        )

        connection.withMutation(keyPath: \.currentRequest) {
          connection.$currentRequest.withLock {
            $0?.httpRequest = partialResult
          }
        }
      } else {
        let partialResult = try? HTTPResponse(head as! HTTPResponseHead)
        connection.withMutation(keyPath: \.response) {
          connection.$response.withLock {
            assert($0 == nil)
            var response = Response()
            response.httpResponse = partialResult
            $0 = response
          }
        }
      }
    case .body(let partialResult):
      if HeadT.self == HTTPRequestHead.self {
        connection.withMutation(keyPath: \.currentRequest) {
          connection.$currentRequest.withLock {
            let body = $0?.body ?? .init()
            $0?.body = body
            $0?.body?.append(contentsOf: Array(buffer: partialResult))
          }
        }
      } else {
        connection.withMutation(keyPath: \.response) {
          connection.$response.withLock {
            let body = $0?.body ?? .init()
            $0?.body = body
            $0?.body?.append(contentsOf: Array(buffer: partialResult))
          }
        }
      }
    case .end(let headers):
      guard let headers else { return }
      let trailers = HTTPFields(headers, splitCookie: false)
      if HeadT.self == HTTPRequestHead.self {
        connection.withMutation(keyPath: \.currentRequest) {
          connection.$currentRequest.withLock {
            $0?.trailerHTTPFields = trailers
          }
        }
      } else {
        connection.withMutation(keyPath: \.response) {
          connection.$response.withLock {
            $0?.trailerHTTPFields = trailers
          }
        }
      }
    }
  }
}
