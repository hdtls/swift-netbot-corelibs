//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

/// The network outbound mode.
@available(SwiftStdlib 5.3, *)
public enum OutboundMode: Sendable {

  /// Direct mode. In this mode all requests will be sent directly.
  case direct

  /// Global proxy mode. In this mode all requests will be forwarded to a proxy server.
  case globalProxy

  /// Rule-based model. In this mode all requests will be forwarded base on rule system.
  case ruleBased
}
