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

@available(SwiftStdlib 5.3, *)
func _chksum(_ data: ByteBuffer, zeroization: Bool = false, offset: Int = 10) -> UInt16 {
  var sum = UInt32.zero

  var i = 0
  while i < data.count {
    // Skip the checksum field itself (assumed to be at offset 10 in 8-bit words)
    if zeroization && i == offset {
      i += 2
      continue
    }
    // Sum all 16-bit words
    let word = UInt16(data[i]) << 8 | (i + 1 < data.count ? UInt16(data[i + 1]) : 0)
    sum += UInt32(word)
    i += 2
  }

  // Fold 32-bit sum to 16 bits
  while sum >> 16 != 0 {
    sum = (sum & 0xFFFF) + (sum >> 16)
  }

  return ~UInt16(sum)
}

@available(SwiftStdlib 5.3, *)
func _chksum(
  _ data: ByteBuffer, pseudoFields: PseudoFields, zeroization: Bool = false, offset: Int = 6
) -> UInt16 {
  var combined = data
  assert(data.readableBytes == pseudoFields.dataLength)

  // 12 bytes pseudo fields
  let pseudoFieldsByteCount =
    pseudoFields.sourceAddress.rawValue.count + pseudoFields.destinationAddress.rawValue.count
    + MemoryLayout<UInt8>.size * 2 + MemoryLayout<UInt16>.size
  combined.clear(minimumCapacity: data.count + pseudoFieldsByteCount)
  combined.writeBytes(pseudoFields.sourceAddress.rawValue)
  combined.writeBytes(pseudoFields.destinationAddress.rawValue)
  combined.writeInteger(pseudoFields.zero)
  combined.writeInteger(pseudoFields.protocol.rawValue)
  combined.writeInteger(pseudoFields.dataLength)
  combined.writeImmutableBuffer(data)
  if combined.readableBytes % 2 == 1 {
    combined.writeInteger(UInt8.zero)
  }

  let chksum = _chksum(combined, zeroization: zeroization, offset: pseudoFieldsByteCount + offset)
  return chksum == 0 ? 0xFFFF : chksum
}
