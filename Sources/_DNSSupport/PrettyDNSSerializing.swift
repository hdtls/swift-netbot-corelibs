//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

@available(SwiftStdlib 5.3, *)
extension Message {

  /// Returns the bytes serialized in DNS message format.
  ///
  /// - throws: notImplemented if resource record is not supported yet.
  public var serializedBytes: [UInt8] {
    get throws {
      var serializedBytes: [UInt8] = []
      var compression: [String: Int] = [:]

      serializedBytes._append(headerFields.transactionID)
      serializedBytes._append(headerFields.flags.rawValue)
      serializedBytes._append(headerFields.qestionCount)
      serializedBytes._append(headerFields.answerCount)
      serializedBytes._append(headerFields.authorityCount)
      serializedBytes._append(headerFields.additionCount)

      for question in questions {
        let labels = question.domainName.split(separator: ".")
        serializedBytes._append(contentsOf: labels, compression: &compression)
        serializedBytes._append(question.queryType.rawValue)
        serializedBytes._append(question.queryClass.rawValue)
      }

      for answerRR in answerRRs {
        try serializedBytes._append(answerRR, compression: &compression)
      }

      for authorityRR in authorityRRs {
        try serializedBytes._append(authorityRR, compression: &compression)
      }

      for additionalRR in additionalRRs {
        try serializedBytes._append(additionalRR, compression: &compression)
      }

      return serializedBytes
    }
  }
}

@available(SwiftStdlib 5.3, *)
extension Array where Element == UInt8 {

  fileprivate mutating func _append(_ newElement: some FixedWidthInteger) {
    var value = newElement.bigEndian
    Swift.withUnsafeBytes(of: &value) {
      append(contentsOf: $0)
    }
  }

  fileprivate mutating func _append(
    contentsOf newElements: [Substring], compression: inout [String: Int]
  ) {
    guard !newElements.isEmpty else {
      append(.zero)
      return
    }

    var labels = newElements[...]
    repeat {
      let key = labels.joined(separator: ".")
      let pointer = compression[key]
      guard pointer == nil else {
        // Found reusable compressed domain.
        // pointer here is validated non-nil, so it is safe to force unwrap the value.
        _append(UInt16(clamping: pointer!) | 0xC000)
        break
      }

      // A new label is here, we need record offset for compressor to use.
      compression[key] = endIndex

      let label = labels[labels.startIndex]
      labels = labels.suffix(from: index(after: labels.startIndex))

      // Write label without compression.
      append(UInt8(label.utf8.count))

      append(contentsOf: label.utf8)

      if labels.isEmpty {
        append(.zero)
      }
    } while !labels.isEmpty
  }

  fileprivate mutating func _append(
    _ newElement: some ResourceRecord, compression: inout [String: Int]
  ) throws {
    var labels = newElement.domainName.split(separator: ".")
    _append(contentsOf: labels, compression: &compression)
    _append(newElement.dataType.rawValue)
    _append(newElement.dataClass.rawValue)
    _append(newElement.ttl)

    let dataLengthBytesStartOffset = endIndex
    // Write placeholder.
    _append(UInt16.zero)

    switch newElement {
    case let rr as ARecord:
      append(contentsOf: rr.data.rawValue)
    case let rr as NSRecord:
      _append(contentsOf: rr.data.split(separator: "."), compression: &compression)
    case let rr as CNAMERecord:
      _append(contentsOf: rr.data.split(separator: "."), compression: &compression)
    case let rr as SOARecord:
      labels = rr.data.primaryNameServer.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
      labels = rr.data.responsibleMailbox.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
      _append(rr.data.serialNumber)
      _append(rr.data.refreshInterval)
      _append(rr.data.retryInterval)
      _append(rr.data.expirationTime)
      _append(rr.data.ttl)
    case let rr as PTRRecord:
      labels = rr.data.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
    case let rr as MXRecord:
      _append(rr.data.preference)
      labels = rr.data.exchange.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
    case let rr as TXTRecord:
      append(UInt8(rr.data.utf8.count))
      append(contentsOf: rr.data.utf8)
    case let rr as AAAARecord:
      append(contentsOf: rr.data.rawValue)
    case let rr as SRVRecord:
      _append(rr.data.priority)
      _append(rr.data.weight)
      _append(rr.data.port)
      labels = rr.data.hostname.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
    case let rr as NAPTRRecord:
      _append(rr.data.order)
      _append(rr.data.preference)
      append(UInt8(rr.data.flags.utf8.count))
      append(contentsOf: rr.data.flags.utf8)
      append(UInt8(rr.data.services.utf8.count))
      append(contentsOf: rr.data.services.utf8)
      append(UInt8(rr.data.regExp.utf8.count))
      append(contentsOf: rr.data.regExp.utf8)
      labels = rr.data.replacement.split(separator: ".")
      _append(contentsOf: labels, compression: &compression)
    case let rr as RAWRecord:
      append(contentsOf: rr.data.readableBytesView)
    default:
      throw PrettyDNSError.notImplemented
    }

    // Replace data length placeholder to determined numer.
    var determined = UInt16(
      clamping: endIndex - dataLengthBytesStartOffset - MemoryLayout<UInt16>.size
    ).bigEndian

    Swift.withUnsafeBytes(of: &determined) {
      replaceSubrange(
        dataLengthBytesStartOffset..<dataLengthBytesStartOffset + MemoryLayout<UInt16>.size,
        with: $0
      )
    }
  }
}
