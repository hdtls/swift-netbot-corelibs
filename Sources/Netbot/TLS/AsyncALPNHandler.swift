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

import NIOTLS

@available(SwiftStdlib 6.0, *)
typealias AsyncALPNHandler = NIOTypedApplicationProtocolNegotiationHandler

/// The error of an ALPN negotiation.
@available(SwiftStdlib 6.0, *)
enum ALPNError: Error {

  /// The token of negotiated is unsupported.
  case negotiatedTokenUnsupported(String)
}
