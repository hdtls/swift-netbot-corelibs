// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import NIOTLS

@available(SwiftStdlib 5.3, *)
typealias AsyncALPNHandler = NIOTypedApplicationProtocolNegotiationHandler

/// The error of an ALPN negotiation.
@available(SwiftStdlib 5.3, *)
enum ALPNError: Error {

  /// The token of negotiated is unsupported.
  case negotiatedTokenUnsupported(String)
}
