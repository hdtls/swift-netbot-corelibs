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

import NEAddressProcessing
import NIOCore

/// Pseudo fields for datagram.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct PseudoFields: Hashable, Sendable {

  /// The IPv4 address of the sender of the packet.
  public var sourceAddress: IPv4Address

  /// The IPv4 address of the intended receiver of the packet.
  public var destinationAddress: IPv4Address

  public var zero = UInt8.zero

  /// Protocol used in the data portion of the IP datagram.
  public var `protocol`: NIOIPProtocol

  /// Length of datagram data.
  public var dataLength: UInt16
}
