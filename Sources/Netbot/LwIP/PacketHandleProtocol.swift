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

@available(SwiftStdlib 5.3, *)
enum PacketHandleResult: Hashable, Sendable {

  /// The handler processed packet.
  case handled

  /// The handler discarded packet.
  case discarded
}

@available(SwiftStdlib 5.3, *)
protocol PacketHandleProtocol {

  func run() async throws

  func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult
}
