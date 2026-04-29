// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2021 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import HTTPTypes
import NIOCore
import NIOHTTP1
import NIOHTTPTypesHTTP1
import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
private protocol HTTPModifier: Sendable {

  /// Predicate for test whether connection is satisfied with the modifier evaluating requires.
  ///
  /// - Parameter connection: The test `Connection`.
  /// - Returns: True if connection is satisfied with the modifier requires.
  func predicate(_ connection: Connection) throws -> Bool
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
private protocol HTTPRequestModifier: HTTPModifier {

  func modify(_ head: HTTPRequest) -> HTTPRequest

  func modify(_ body: ByteBuffer) -> ByteBuffer

  func modify(_ end: HTTPFields) -> HTTPFields
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
private protocol HTTPResponseModifier: HTTPModifier {

  func modify(_ head: HTTPResponse) -> HTTPResponse

  func modify(_ body: ByteBuffer) -> ByteBuffer

  func modify(_ end: HTTPFields) -> HTTPFields
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class __CapabilitiesProcessingHandler<HeadT: Equatable & Sendable>: ChannelInboundHandler,
  Sendable
{
  typealias InboundIn = HTTPPart<HeadT, ByteBuffer>
  typealias InboundOut = HTTPPart<HeadT, IOData>

  private let connection: Connection
  private let enabledHTTPCapabilities: CapabilityFlags
  private let modifiers: [any HTTPModifier]
  private let application: AnalyzeBot

  init(
    application: AnalyzeBot,
    connection: Connection,
    enabledHTTPCapabilities: CapabilityFlags
  ) {
    self.connection = connection
    self.enabledHTTPCapabilities = enabledHTTPCapabilities
    self.modifiers = []
    self.application = application

    guard HeadT.self == HTTPRequestHead.self || HeadT.self == HTTPResponseHead.self else {
      preconditionFailure("unknown HTTP head part type \(HeadT.self)")
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    if HeadT.self == HTTPRequestHead.self {
      context.fireChannelRead(processHTTPRequest(data))
    } else {
      context.fireChannelRead(processHTTPResponse(data))
    }
  }

  func processHTTPRequest(_ data: NIOAny) -> NIOAny {
    let httpPart = unwrapInboundIn(data)

    var modifiers: [any HTTPRequestModifier]?
    if enabledHTTPCapabilities.contains(.rewrite) {
      modifiers = self.modifiers
        .compactMap { modifier -> (any HTTPRequestModifier)? in
          guard let modifier = modifier as? any HTTPRequestModifier else {
            return nil
          }
          let modifiable = try? connection.satisfy(predicate: modifier.predicate(_:))
          return modifiable == true ? modifier : nil
        }
    }

    switch httpPart {
    case .head(let head):
      do {
        var partialResult = try HTTPRequest(
          head as! HTTPRequestHead,
          secure: connection.tls,
          splitCookie: false
        )

        if let modifiers {
          // Modify HTTP request.
          partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
            modifier.modify(partialResult)
          }
        }

        // Capture modified HTTP request.
        if enabledHTTPCapabilities.contains(.httpCapture) {
          connection.currentRequest?.httpRequest = partialResult
        }

        let finalize = try HTTPRequestHead(partialResult) as! HeadT
        return wrapInboundOut(.head(finalize))
      } catch {
        return wrapInboundOut(.head(head))
      }
    case .body(var partialResult):
      if let modifiers {
        // Modify HTTP request body.
        partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
          modifier.modify(partialResult)
        }
      }

      // Capature HTTP request body.
      if enabledHTTPCapabilities.contains(.httpCapture) {
        connection._currentRequest.withLock {
          let body = $0?.body ?? .init()
          $0?.body = body
          $0?.body?.append(contentsOf: Array(buffer: partialResult))
        }
      }

      return wrapInboundOut(.body(.byteBuffer(partialResult)))
    case .end(let trailers):
      guard let trailers else {
        return wrapInboundOut(.end(trailers))
      }

      guard let modifiers else {
        return wrapInboundOut(.end(trailers))
      }

      var partialResult = HTTPFields(trailers, splitCookie: false)
      // Modify HTTP request end.
      partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
        modifier.modify(partialResult)
      }
      return wrapInboundOut(.end(HTTPHeaders(partialResult)))
    }
  }

  func processHTTPResponse(_ data: NIOAny) -> NIOAny {
    let httpPart = unwrapInboundIn(data)

    var modifiers: [any HTTPResponseModifier]?
    if enabledHTTPCapabilities.contains(.rewrite) {
      modifiers = self.modifiers
        .compactMap {
          guard let modifier = $0 as? any HTTPResponseModifier else {
            return nil
          }
          let modifiable = try? connection.satisfy(predicate: modifier.predicate(_:))
          return modifiable == true ? modifier : nil
        }
    }

    switch httpPart {
    case .head(let head):
      do {
        var partialResult = try HTTPResponse(head as! HTTPResponseHead)

        if let modifiers {
          // Modify HTTP response.
          partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
            modifier.modify(partialResult)
          }
        }

        // Capture modified HTTP response
        if enabledHTTPCapabilities.contains(.httpCapture) {
          connection.response = Response(httpResponse: partialResult)
        }

        let finalize = HTTPResponseHead(partialResult) as! HeadT
        return wrapInboundOut(.head(finalize))
      } catch {
        return wrapInboundOut(.head(head))
      }
    case .body(var partialResult):
      if let modifiers {
        partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
          modifier.modify(partialResult)
        }
      }

      if enabledHTTPCapabilities.contains(.httpCapture) {
        connection._response.withLock {
          let body = $0?.body ?? .init()
          $0?.body = body
          $0?.body?.append(contentsOf: Array(buffer: partialResult))
        }
      }
      return wrapInboundOut(.body(.byteBuffer(partialResult)))
    case .end(let trailers):
      connection._duration = -connection.earliestBeginDate.timeIntervalSinceNow
      connection.state = .completed
      guard let trailers else {
        return wrapInboundOut(.end(trailers))
      }

      guard let modifiers else {
        return wrapInboundOut(.end(trailers))
      }

      var partialResult = HTTPFields(trailers, splitCookie: false)
      // Modify HTTP request end.
      partialResult = modifiers.reduce(partialResult) { partialResult, modifier in
        modifier.modify(partialResult)
      }
      return wrapInboundOut(.end(HTTPHeaders(partialResult)))
    }
  }
}
