//
// See LICENSE.txt for license information
//

// TODO: Duplicated with NEPrettyBytes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

enum ByteHexEncodingErrors: Error {
  case incorrectHexValue
  case incorrectString
}

let charA = UInt8(UnicodeScalar("a").value)
let char0 = UInt8(UnicodeScalar("0").value)

private func itoh(_ value: UInt8) -> UInt8 {
  return (value > 9) ? (charA + value - 10) : (char0 + value)
}

private func htoi(_ value: UInt8) throws -> UInt8 {
  switch value {
  case char0...char0 + 9:
    return value - char0
  case charA...charA + 5:
    return value - charA + 10
  default:
    throw ByteHexEncodingErrors.incorrectHexValue
  }
}

extension DataProtocol {

  func hexEncodedString() -> String {
    let hexLen = self.count * 2
    var hexChars = [UInt8](repeating: 0, count: hexLen)
    var offset = 0

    for _ in self.regions {
      for i in self {
        hexChars[Int(offset * 2)] = itoh((i >> 4) & 0xF)
        hexChars[Int(offset * 2 + 1)] = itoh(i & 0xF)
        offset += 1
      }
    }

    return String(bytes: hexChars, encoding: .utf8)!
  }
}
