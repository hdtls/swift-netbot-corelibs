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

@available(SwiftStdlib 6.0, *)
final class OnDiskHTTPCapture<HeadT: Equatable & Sendable>: ChannelInboundHandler, Sendable {

  typealias InboundIn = HTTPPart<HeadT, ByteBuffer>
  typealias InboundOut = HTTPPart<HeadT, IOData>

  private let onDiskHTTPCaptureFilters: [String]
  private let connection: Connection

  init(connection: Connection, captureFilters: [String]) {
    self.connection = connection
    self.onDiskHTTPCaptureFilters = captureFilters

    guard HeadT.self == HTTPRequestHead.self || HeadT.self == HTTPResponseHead.self else {
      preconditionFailure("unknown HTTP head part type \(HeadT.self)")
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let unwrapped = unwrapInboundIn(data)
    Task {
      if HeadT.self == HTTPRequestHead.self {
        await onDiskHTTPRequestCapture(unwrapped)
      } else {
        await onDiskHTTPResponseCapture(unwrapped)
      }
    }

    context.fireChannelRead(data)
  }

  func onDiskHTTPRequestCapture(_ unwrapped: InboundIn) async {}

  func onDiskHTTPResponseCapture(_ unwrapped: InboundIn) async {}
}
